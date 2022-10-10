local async = require("neotest.async")
local lib = require("neotest.lib")
local Path = require("plenary.path")
local xml = require("neotest.lib.xml")

local CTestNeotestAdapter = { name = "neotest-ctest" }

-- TODO: Are these patterns enough?
CTestNeotestAdapter.root = lib.files.match_root_pattern("build", "CMakeLists.txt", ".git")

function CTestNeotestAdapter.is_test_file(file_path)
  local elems = vim.split(file_path, Path.path.sep, { plain = true })
  local filename = elems[#elems]
  local test_extensions = {
    ["C"] = true,
    ["cc"] = true,
    ["cpp"] = true,
    ["CPP"] = true,
    ["c++"] = true,
    ["cp"] = true,
    ["cxx"] = true,
  }

  if filename == "" then -- directory
    return false
  end

  local extsplit = vim.split(filename, ".", { plain = true })
  local extension = extsplit[#extsplit]

  -- Don't make assumption on wether test files are prefixed or suffixed
  -- with test_ or _test (which is a very common naming convention though).
  -- We just check wether the filename contains the words test or Test.
  local regex = vim.regex(".*[tT]est.*")
  local result = test_extensions[extension] and (regex:match_str(filename) ~= nil) or false

  return result
end

function CTestNeotestAdapter.discover_positions(path)
  local query = [[
  ((function_definition
  	declarator: (
        function_declarator
          declarator: (identifier) @test.kind
        parameters: (
          parameter_list
            . (parameter_declaration type: (type_identifier) !declarator) @namespace.name
            . (parameter_declaration type: (type_identifier) !declarator) @test.name
            .
        )
      )
      !type
  )
  (#any-of? @test.kind "TEST" "TEST_F" "TEST_P"))
  @test.definition
  ]]

  return lib.treesitter.parse_positions(path, query)
end

function CTestNeotestAdapter.build_spec(args)
  -- TODO: Figure out what is passed through 'args'
  local position = args.tree:data()
  local path = position.path
  local root = CTestNeotestAdapter.root(path)
  local junit_path = async.fn.tempname() .. ".junit.xml"

  -- TODO: Need to test for kind? I.e. TEST vs TEST_F vs TEST_P
  local test_filter
  if position.type == "test" then
    -- TODO: confirm
    local parts = vim.split(position.id, "::", { plain = true })
    assert(#parts == 3, "bad position")
    local test_name = parts[3]
    test_filter = "-R " .. test_name
  elseif position.type == "namespace" then
    -- TODO: confirm
    local parts = vim.split(position.id, "::", { plain = true })
    assert(#parts == 3, "bad position")
    local test_namespace = parts[2]
    test_filter = "-R " .. test_namespace
  elseif position.type == "file" then
    -- TODO: I don't think -R option will be useful here.
    -- The -I option would be more useful, but this requires mapping test numbers/index
    -- to test names in the file. To gather the mapping, the following must be run:
    --     `ctest --test-dir build -Q -N --output-log some.log`
    -- and then parse the output log, and match the test number with the test names.
    -- NOTE: -I option cam be specified multiple times
  elseif position.tupe == "dir" then
    -- TODO: Same method as for file I guess
  elseif position.type == "suite" then
    -- NOTE: No need to specify filters since we're running all tests
  end

  local command = vim.tbl_flatten({
    "ctest",
    "--test-dir build",
    "--quiet",
    --    "--not-tests=ignore",  -- If not tests are found, then ctest will not return an error
    "--output-on-failure",
    "--output-junit " .. junit_path,
    vim.list_extend(test_filter or {}, args.extra_args or {}),
  })

  return { command = command, context = { junit_path = junit_path } }
end

function CTestNeotestAdapter.results(spec, result)
  local data

  with(open(spec.context.junit_path, "r"), function(reader)
    data = reader:read("*a")
  end)

  local handler = xml_tree:new()
  local parser = xml.parser(handler)
  parser:parse(data)

  local testcases
  if #handler.root.testsuites.testsuite.testcase == 0 then
    testcases = { handler.root.testsuites.testsuite.testcase }
  else
    testcases = handler.root.testsuites.testsuite.testcase
  end

  local results = {}

  for _, testcase in pairs(testcases) do
    if testcase.failure then
      results[testcase._attr.name] = {
        status = "failed",
        short = testcase.failure[1],
      }
    else
      results[testcase._attr.name] = {
        status = "passed",
      }
    end
  end

  -- TODO cd back into root workspace?

  return results
end

-- TODO Not needed unless setmetatable is used
local is_callable = function(obj)
  return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

-- TODO Document adapter config
setmetatable(CTestNeotestAdapter, {
  __call = function(_, opts)
    is_test_file = opts.is_test_file or is_test_file

    if is_callable(opts.args) then
      get_args = opts.args
    elseif opts.args then
      get_args = function()
        return opts.args
      end
    end

    if type(opts.dap) == "table" then
      dap_args = opts.dap
    end

    return CTestNeotestAdapter
  end,
})

return CTestNeotestAdapter
