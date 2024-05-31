local nio = require("nio")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local parse = require("neotest-ctest.parse")
local Path = require("plenary.path")
local Scandir = require("plenary.scandir")
local xml = require("neotest.lib.xml")
local utils = require("neotest-ctest.utils")

local adapter = { name = "neotest-ctest" }

function adapter.root(dir)
  local possible_ctest_test_dirs = Scandir.scan_dir(dir, {
    respect_gitignore = false, -- NOTE: The build directory is almost certainly gitignore'd.
    depth = 2,
    search_pattern = "CTestTestfile.cmake",
    silent = true,
  })

  -- TODO: logging

  if #possible_ctest_test_dirs == 0 then
    -- Either the project has not been built, or CTest has not been enabled for any of the
    -- project configurations
    return
  end

  -- Use the first configuration found. This is where we will instruct ctest to look for tests.
  adapter.test_dir = lib.files.parent(possible_ctest_test_dirs[1])

  return dir
end

-- Returns false for any directory that should not be considered by neotest
function adapter.filter_dir(name)
  -- TODO: Use regex matching instead?
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
  -- TODO: Should query ctest?
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
  local treesitter_query = vim.treesitter.query.parse("cpp", query)
  return parse.parse_positions(path, treesitter_query)
end

-- TODO: unit tests
function adapter.build_spec(args)
  local results_path = nio.fn.tempname()
  local position = args.tree:data()

  local result, test_filters = utils.filter_tests(adapter.test_dir, args.tree)
  if result ~= 0 then
    return {}
  end

  -- TODO: Use vim.iter instead
  local command = vim.tbl_flatten({
    "ctest",
    "--test-dir " .. adapter.test_dir,
    "--quiet",
    "--output-on-failure",
    "--output-junit " .. results_path,
    vim.iter(args.extra_args or {}):flatten(),
    vim.iter(test_filters or {}):flatten(),
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
    and (nio.fn.filereadable(spec.context.results_path))
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

  if not nio.fn.filereadable(results_path) then
    logger.error(adapter.name .. ": ctest result output does not exist")
    return utils.handle_testcases(nil, tree)
  end

  local content = lib.files.read(results_path)
  local handler = xml.parse(content)

  -- TODO: Not sure if ctest supports the handler.root.testsuites pattern (multiple testsuites)
  local testsuite = handler.root and handler.root.testsuite or handler.testsuite
  local testcases = testsuite.testcase or nil

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
        local output = nio.fn.tempname()
        local short, start_index, end_index

        _, start_index = string.find(detailed, "%[%s+RUN%s+%] ")
        end_index, _ = string.find(detailed, "%[%s+FAILED%s+%] ")
        short = string.sub(detailed, start_index + 1, end_index - 1)

        -- TODO: newlines not preserved
        vim.fn.writefile({ detailed }, output)

        results[id] = { status = "failed", short = short }
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
