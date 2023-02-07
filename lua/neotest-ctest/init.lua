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
-- while searching for test files.
function adapter.filter_dir(name)
  -- Add any directory that should be filtered here
  local dir_filters = {
    [".git"] = false,
    [".cache"] = false,
    [".venv"] = false,
    ["build"] = false,
    ["venv"] = false,
    ["submodules"] = false,
    ["extern"] = false,
    ["data"] = false,
    ["cmake"] = false,
    ["docs"] = false,
    ["apps"] = false,
    ["include"] = false,
    ["libs"] = false,
  }

  return dir_filters[name] == nil
end

function adapter.is_test_file(file_path)
  local elems = vim.split(file_path, Path.path.sep, { plain = true })
  local basename = elems[#elems]
  local test_extensions = {
    ["C"] = true,
    ["cc"] = true,
    ["cpp"] = true,
    ["CPP"] = true,
    ["c++"] = true,
    ["cp"] = true,
    ["cxx"] = true, -- TODO: more?
  }

  if basename == "" then
    -- directory
    return false
  end

  local extsplit = vim.split(basename, ".", { plain = true })
  local extension = extsplit[#extsplit]

  -- Return early if file doesn't have correct extension
  if test_extensions[extension] == nil then
    return false
  end

  local filename = extsplit[1]
  -- remove first and last (extension) element
  extsplit[#extsplit] = nil
  extsplit[1] = nil
  -- Build the filename in case basename included multiple `.` in it
  for _, word in pairs(extsplit) do
    filename = filename .. "." .. word
  end

  local match = false
  if (string.find(filename, "^test[_%.].*") ~= nil) or (string.find(filename, "^Test%u.*") ~= nil) then
    -- matched starts with
    match = true
  elseif (string.find(filename, ".*[_%.]test$") ~= nil) or (string.find(filename, ".*[a-z]Tests?$") ~= nil) then
    -- matched ends with
    match = true
  elseif string.find(filename, ".*[_%.]test[_%.].*") ~= nil then
    -- matched in-between
    match = true
  end

  return match
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
        -- Not sure whether "system-out" is the prefered entry to read in the future,
        -- but it's the only option we have for now until ctest junit reports have matured.
        -- See https://gitlab.kitware.com/cmake/cmake/-/issues/22478
        local detailed = testcase["system-out"]
        local short, start_index, end_index

        -- This is a best effort to sanitize system-out to give a short error message
        -- Seem to work quite well though, but should test some more...
        _, start_index = string.find(detailed, "%[%s+RUN%s+%] " .. id)
        end_index, _ = string.find(detailed, "%[%s+FAILED%s+%] ")
        short = string.sub(detailed, start_index + 1, end_index - 1)

        -- TODO: Not sure it makes much sense pointing output to the entire
        -- results_path... this is an xml document containing all results,
        -- which would be inconvenient to navigate if there's a lot of tests...
        results[id] = { status = "failed", short = short, output = results_path }
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
