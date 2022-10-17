local async = require("neotest.async")
local context_manager = require("plenary.context_manager")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local open = context_manager.open
local parse = require("neotest-ctest.parse")
local Path = require("plenary.path")
local xml = require("neotest.lib.xml")
local xml_tree = require("neotest.lib.xml.tree")
local utils = require("neotest-ctest.utils")
local with = context_manager.with

local adapter = { name = "neotest-ctest" }

-- TODO: Improve root pattern matching
-- For better accuracy, we should probably test that both a build folder AND
-- a CMakeLists.txt exist in the project root. However, match_root_pattern
-- only checks the inputs independently, so that won't work since it's quite
-- common to place CMakeLists in subdirectories (even in the same directory)
-- where tests are implemented. So we should probably implement our own
-- method.
-- BUG?: Neotest executes neotest-ctest even if build directory does not exist
adapter.root = lib.files.match_root_pattern("build")

-- Returns false for any directory that should not be considered by neotest
function adapter.filter_dir(name)
  local dir_filters = {
    [".git"] = false, -- TODO: Does neotest check hidden folders?
    ["build"] = false,
    [".cache"] = false,
    ["venv"] = false,
    [".venv"] = false,
  }

  return dir_filters[name] == nil
end

function adapter.is_test_file(file_path)
  local elems = vim.split(file_path, Path.path.sep, { plain = true })
  local filename = elems[#elems]
  local test_extensions = {
    ["C"] = true,
    ["cc"] = true,
    ["cpp"] = true,
    ["CPP"] = true,
    ["c++"] = true,
    ["cp"] = true,
    ["cxx"] = true, -- TODO: more?
  }

  if filename == "" then -- directory
    return false
  end

  local extsplit = vim.split(filename, ".", { plain = true })
  local extension = extsplit[#extsplit]

  -- Return early if file doesn't have correct extension
  if test_extensions[extension] == nil then
    return false
  end

  -- Don't make assumption on wether test files are prefixed or suffixed
  -- with [tT]est or [tT]est (which is a very common naming convention though).
  -- We just check wether the filename contains the words test or Test, and
  -- hopefully that will capture most patterns.
  local match = string.find(filename, "[tT]est")
  return match ~= nil
end

function adapter.discover_positions(path)
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

  -- TODO: The parser should probably have its pos.id include path::fixture::test, and the name should be: fixture::test?
  -- Not sure about the consequences of not including the path in the pos.id
  -- Maybe this is the reason nvim crashes?
  query = vim.treesitter.query.parse_query("cpp", query)
  return parse.parse_positions(path, query)
end

-- TODO: unit tests
function adapter.build_spec(args)
  local results_path = async.fn.tempname()
  local position = args.tree:data()
  local path = position.path
  local root = adapter.root(path)

  -- Check that test directory exists
  if (root == nil) or (not lib.files.is_dir(root .. "/build")) then
    logger.error("neotest-ctest: Could not find ctest test directory")
    return {}
  end

  -- TODO: Maybe allow users to choose whether we should run cmake before
  -- executing tests?
  local result, test_filters = utils.filter_tests(root, args.tree)
  if result ~= 0 then
    return {}
  end

  local command = vim.tbl_flatten({
    "ctest",
    "--test-dir " .. root .. "/build",
    "--quiet",
    "--output-on-failure",
    "--output-junit " .. results_path,
    vim.tbl_flatten(args.extra_args or {}),
    vim.tbl_flatten(test_filters or {}),
  })

  return {
    command = table.concat(command, " "),
    context = {
      results_path = results_path,
      file = position.path,
    },
  }
end

function adapter.results(spec, result, tree)
  local results = {}
  local discovered_tests = utils.discover_tests(tree)

  if
    (spec.context ~= nil)
    and (spec.context.results_path ~= nil)
    and (async.fn.filereadable(spec.context.results_path))
  then
    -- continue
  else
    -- Mark all discovered tests as skipped.
    logger.error("neotest-ctest: no test results to parse")
    for _, id in pairs(discovered_tests) do
      results[id] = { status = "skipped" }
    end
    return results
  end

  local results_path = spec.context.results_path
  local handler = xml_tree()
  local parser = xml.parser(handler)
  local data

  if not async.fn.filereadable(results_path) then
    logger.error(adapter.name .. ": ctest result output does not exist")
    return utils.handle_testcases(nil, tree)
  end

  with(open(results_path, "r"), function(reader)
    data = reader:read("*a")
  end)

  parser:parse(data)

  -- TODO: Not sure if ctest supports the handler.root.testsuites pattern (multiple testsuites)
  local testsuite = nil
  local testcases = nil

  if handler.root.testsuite then
    testsuite = handler.root.testsuite
    if testsuite.testcase then
      testcases = testsuite.testcase
    end
  end

  if (testcases ~= nil) and (#testcases == 0) then
    testcases = { testcases }
  end

  if testcases ~= nil then
    for _, testcase in pairs(testcases) do
      local id = testcase._attr.name
      local status = testcase._attr.status

      -- remove handled testcase
      discovered_tests[id] = nil

      if status == "run" then
        results[id] = { status = "passed" }
      elseif status == "fail" then
        local detailed = testcase["system-out"]
        local output = async.fn.tempname()
        local short, start_index, end_index

        _, start_index = string.find(detailed, "%[%s+RUN%s+%] ")
        end_index, _ = string.find(detailed, "%[%s+FAILED%s+%] ")
        short = string.sub(detailed, start_index + 1, end_index - 1)

        -- TODO: newlines not preserved
        vim.fn.writefile({ detailed }, output)

        results[id] = { status = "failed", short = short, output = output }
      end
    end
  end

  -- Mark all other tests not executed by ctest as skipped.
  for _, id in pairs(discovered_tests) do
    results[id] = { status = "skipped" }
  end

  return results
end

return adapter
