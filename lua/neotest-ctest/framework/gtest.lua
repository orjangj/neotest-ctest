local logger = require("neotest.logging")
local gtest = {}

gtest.lang = "cpp"
gtest.include_query = [[
  ;; query
  (preproc_include
    path: (system_lib_string) @system.include
    (#match? @system.include "^\\<(gtest/)?gtest\.h\\>$")
  )
  ;; query
  (preproc_include
    path: (string_literal) @local.include
    (#match? @local.include "^\"(gtest/)?gtest\.h\"$")
  )
]]
gtest.tests_query = [[
  ;; query
  ((namespace_definition
    name: (namespace_identifier) @namespace.name
  )) @namespace.definition
  ;; query
  ((function_definition
    declarator: (function_declarator
      declarator: (identifier) @test.kind (#any-of? @test.kind "TEST" "TEST_F")
      parameters: (parameter_list
        . (parameter_declaration type: (type_identifier) !declarator) @test.suite
        . (parameter_declaration type: (type_identifier) !declarator) @test.name
        .
      )
    )
  )) @test.definition
  ;; query
  ((function_definition
    declarator: (function_declarator
      declarator: (identifier) @namespace.name (#any-of? @namespace.name "TEST_P" "TYPED_TEST" "TYPED_TEST_P")
      parameters: (parameter_list
        . (parameter_declaration type: (type_identifier) !declarator) @namespace.suite
        . (parameter_declaration type: (type_identifier) !declarator) @namespace.test
        .
      )
    )
  )) @namespace.definition
]]

local function newest_mtime(paths)
  local sec, nsec = 0, 0
  for _, p in ipairs(paths) do
    local stat = vim.loop.fs_stat(p)
    local mtime = stat and stat.mtime
    local is_newer = mtime and (mtime.sec > sec or (mtime.sec == sec and (mtime.nsec or 0) > nsec))
    if mtime and is_newer then
      sec, nsec = mtime.sec, mtime.nsec or 0
    end
  end
  return sec .. ":" .. nsec
end

local function mtime_of(path)
  return newest_mtime({ path })
end

-- Caching because we use the ctest --show-only=json-v1 to get
-- generated tests not visible in a different reasonable manner.
-- Otherwise we would run the command once for each file which
-- can get expensive fast.
local cache = {
  root = nil,
  root_mtime = nil,
  test_dir = nil,
  watch = nil,
  fingerprint = nil,
  test_names = nil,
}

---@param path string
local function get_project_root(path)
  local ok_root, root = pcall(function()
    return require("neotest-ctest.config").root(vim.fs.dirname(path))
  end)
  if not ok_root or not root then
    return nil
  end
  return root
end

---@param root string
---@param test_dir string
---@return string[]| nil test_names
---@return string[] watch
local function query_ctest(root, test_dir)
  local ctest = require("neotest-ctest.ctest")

  local ok, res = pcall(function()
    return ctest:new(root):testcases()
  end)

  local names, executables, seen = nil, {}, {}
  if ok and type(res) == "table" then
    names = {}
    for name, meta in pairs(res) do
      names[#names + 1] = name
      local exe = meta and meta.executable
      if exe and not seen[exe] then
        seen[exe] = true
        executables[#executables + 1] = exe
      end
    end
  end
  local watch = { test_dir .. "/CTestTestfile.cmake" }
  vim.list_extend(watch, executables)
  return names, watch
end

---@param path string
---@return string[] | nil
function gtest.ctest_test_names(path)
  local root = get_project_root(path)
  if not root then
    return nil
  end
  local ctest = require("neotest-ctest.ctest")
  local root_mtime = mtime_of(root)
  local test_dir = cache.test_dir
  local root_different = cache.root ~= root
  local root_modified = cache.root_mtime ~= root_mtime
  if root_different or root_modified then
    local ok_dir, dir = pcall(ctest.find_test_dir, root)
    test_dir = ok_dir and dir or nil
  end

  if not test_dir then
    cache = { root = root, root_mtime = root_mtime }
    return nil
  end

  local cache_can_be_used = cache.root == root
    and cache.test_dir == test_dir
    and cache.watch
    and newest_mtime(cache.watch) == cache.fingerprint

  if cache_can_be_used then
    return cache.test_names
  end

  local test_names, watch = query_ctest(root, test_dir)
  cache = {
    root = root,
    root_mtime = root_mtime,
    test_dir = test_dir,
    watch = watch,
    fingerprint = newest_mtime(watch),
    test_names = test_names,
  }

  return test_names
end

-- Finds if the test expanded_testname generated from suite.test
---@param expanded_testname string
---@param suite string
---@param test string
---@return boolean
function gtest.is_test_generated_from(expanded_testname, suite, test)
  local s = vim.pesc(suite)
  local t = vim.pesc(test)

  -- Prepend a "/" so `/<suite>` is a left boundary whether the suite sits at the
  -- start of the name or after an instantiation prefix ("Ints/Suite.Test/0").
  local slashed = "/" .. expanded_testname

  -- Suite.Test -- plain / single instantiation. `$` so "A.B" rejects "A.Bextra".
  if slashed:match("/" .. s .. "%." .. t .. "$") then
    return true
  end
  -- Suite.Test<TypeParam>  (TYPED_TEST) -- trailing `<`
  -- Prefix/Suite.Test/0    (TEST_P)                                 -- trailing `/`
  if slashed:match("/" .. s .. "%." .. t .. "[/<]") then
    return true
  end
  -- Prefix/Suite/0.Test -- TYPED_TEST_P: the numeric instantiation index sits
  -- between suite and test rather than after the test.
  if slashed:match("/" .. s .. "/%d+%." .. t .. "$") then
    return true
  end
  return false
end

---@param file_path string
---@param suite string
---@param test string
local function typed_instances(file_path, suite, test)
  local names = gtest.ctest_test_names(file_path)
  if not names then
    return {}
  end

  local positions = {}
  for _, expanded_testname in ipairs(names) do
    if gtest.is_test_generated_from(expanded_testname, suite, test) then
      positions[#positions + 1] = { type = "test", path = file_path, name = expanded_testname }
    end
  end
  table.sort(positions, function(a, b)
    return a.name < b.name
  end)
  return positions
end

function gtest.parse_errors(output)
  local capture = vim.trim(string.match(output, "%[%s+RUN%s+%].-[\r\n](.-)%[%s+FAILED%s+%]"))

  if not capture then
    logger.error("Failed to capture gtest errors")
    return {}
  end

  -- NOTE: This is a very hacky solution to transform gtest <v1.14.0 to a v.14.0+ formatted error message output
  local tmp = ""
  for str in string.gmatch(capture, "[^\r\n$]+") do
    local line = string.match(str, ".-:(%d+):%sFailure")
    if line then
      tmp = tmp .. "\n\n" .. str
    else
      tmp = tmp .. "\n" .. str
    end
  end

  capture = vim.trim(tmp)

  -- NOTE: At this point, the capture should be compatible with gtest v1.14.0+ (which is considerably easier to parse)
  local errors = {}

  for failures in string.gmatch(capture .. "\n\n", "(.-)[\r\n][\r\n]") do
    for line, message in string.gmatch(failures, ".-:(%d+):%sFailure[\r\n](.+)") do
      table.insert(errors, { line = tonumber(line), message = message })
    end
  end

  return errors
end

function gtest.build_parameterized(source, parent)
  local query = ([[
    ;; query
    ((expression_statement
      (call_expression
        function: (identifier) @parameterized.kind (#any-of? @parameterized.kind "INSTANTIATE_TEST_SUITE_P")
        arguments: (argument_list
          . (identifier) @parameterized.group
          . (identifier) @parameterized.suite (#eq? @parameterized.suite "%s")
          . (call_expression
              function: (qualified_identifier
                name: (identifier) @parameterized.param_generator)
              arguments: (argument_list) @parameterized.param_args
            )
        )
      )
    )) @parameterized.definition
  ]]):format(parent.suite)

  local nio = require("nio")
  local lib = require("neotest.lib")

  nio.scheduler()

  local lang_tree = vim.treesitter.get_string_parser(
    source,
    gtest.lang,
    -- Prevent neovim from trying to read the query from injection files
    { injections = { [string.format("%s", gtest.lang)] = "" } }
  )

  local root = lib.treesitter.fast_parse(lang_tree):root()
  local normalized_query = lib.treesitter.normalise_query(gtest.lang, query)

  local positions = {}

  for _, match in normalized_query:iter_matches(root, source, nil, nil, { all = true }) do
    local captured_nodes = {}
    for i, capture in ipairs(normalized_query.captures) do
      captured_nodes[capture] = match[i] and match[i][1] or nil
    end

    local group = vim.treesitter.get_node_text(captured_nodes["parameterized.group"], source)
    local param_generator =
      vim.treesitter.get_node_text(captured_nodes["parameterized.param_generator"], source)
    local param_args =
      vim.treesitter.get_node_text(captured_nodes["parameterized.param_args"], source)

    -- TODO: support name_generator
    local prefix = group

    if param_generator == "Range" then
      local p_range = vim.split(string.match(param_args, "%((.-)%)"), ",")
      local p_begin = tonumber(p_range[1])
      local p_end = tonumber(p_range[2]) - 1
      local p_step = tonumber(p_range[3]) or 1

      for i = p_begin, p_end, p_step do
        table.insert(positions, {
          type = "test",
          path = parent.file_path,
          name = prefix .. "/" .. parent.name .. "/" .. i,
        })
      end
    elseif param_generator == "Values" then
      local p_values = vim.split(string.match(param_args, "%((.-)%)"), ",")
      for _, v in pairs(p_values) do
        table.insert(positions, {
          type = "test",
          path = parent.file_path,
          name = prefix .. "/" .. parent.name .. "/" .. vim.trim(v),
        })
      end
    elseif param_generator == "ValuesIn" then
    elseif param_generator == "Bool" then
      local p_values = { "false", "true" }
      for _, v in pairs(p_values) do
        table.insert(positions, {
          type = "test",
          path = parent.file_path,
          name = prefix .. "/" .. parent.name .. "/" .. v,
        })
      end
    end
  end

  return positions
end

-- generator is basically typed tests and parameterized tests
-- if there is a different term it could be more suitable here
local function build_generator_parent_test(file_path, name, range, expand)
  local namespace = { type = "namespace", path = file_path, name = name, range = range }
  local children = expand() or {}

  if #children == 0 then
    return { namespace, { type = "test", path = file_path, name = name } }
  end

  local result = { namespace }
  for _, child in ipairs(children) do
    result[#result + 1] = child
  end
  return result
end

function gtest.build_position(file_path, source, captured_nodes)
  local position

  if captured_nodes["test.name"] then
    ---@type string
    local suite = vim.treesitter.get_node_text(captured_nodes["test.suite"], source)
    local name = vim.treesitter.get_node_text(captured_nodes["test.name"], source)
    local range = { captured_nodes["test.definition"]:range() }

    position = {
      type = "test",
      path = file_path,
      name = suite .. "." .. name,
      range = range,
    }
  elseif captured_nodes["namespace.name"] then
    ---@type string
    local name = vim.treesitter.get_node_text(captured_nodes["namespace.name"], source)
    local range = { captured_nodes["namespace.definition"]:range() }

    if captured_nodes["namespace.suite"] then
      --- (TEST_P,TYPED_TEST,TYPED_TEST_P) macros
      local suite = vim.treesitter.get_node_text(captured_nodes["namespace.suite"], source)
      local test = vim.treesitter.get_node_text(captured_nodes["namespace.test"], source)
      local parent = suite .. "." .. test
      position = build_generator_parent_test(file_path, parent, range, function()
        if name == "TEST_P" then
          local params = gtest.build_parameterized(source, {
            suite = suite,
            name = parent,
            file_path = file_path,
          })
          if #params > 0 then
            return params
          end
        end
        --- (TYPED_TEST,TYPED_TEST_P) macros
        return typed_instances(file_path, suite, test)
      end)
    else
      position = {
        type = "namespace",
        path = file_path,
        name = name,
        range = range,
      }
    end
  end
  return position
end

function gtest.parse_positions(path)
  local lib = require("neotest.lib")
  local opts = { build_position = "require('neotest-ctest.framework.gtest').build_position" }
  return lib.treesitter.parse_positions(path, gtest.tests_query, opts)
end

return gtest
