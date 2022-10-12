local async = require("neotest.async")
local context_manager = require("plenary.context_manager")
local lib = require("neotest.lib")
local open = context_manager.open
local Path = require("plenary.path")
local xml = require("neotest.lib.xml")
local xml_tree = require("neotest.lib.xml.tree")
local utils = require("neotest-ctest.utils")
local with = context_manager.with

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
    ["cxx"] = true, -- TODO: more?
  }

  if filename == "" then -- directory
    return false
  end

  local extsplit = vim.split(filename, ".", { plain = true })
  local extension = extsplit[#extsplit]

  -- Don't make assumption on wether test files are prefixed or suffixed
  -- with [tT]est or [tT]est (which is a very common naming convention though).
  -- We just check wether the filename contains the words test or Test, and
  -- hopefully that will capture most patterns.
  local regex = vim.regex(".*[tT]est.*")
  local result = test_extensions[extension] and (regex:match_str(filename) ~= nil) or false

  return result
end

-- TODO: The query should return position.id as FixtureName::TestName
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

  query = vim.treesitter.query.parse_query("cpp", query)
  return require("neotest-ctest.parse").parse_positions(path, query)
end

function CTestNeotestAdapter.build_spec(args)
  -- TODO: Unit tests
  local position = args.tree:data()
  local path = position.path
  local root = CTestNeotestAdapter.root(path)
  local junit_path = async.fn.tempname() .. ".junit.xml"

  -- TODO: Maybe allow users to choose whether we should run cmake before
  -- executing tests?

  local result, test_filters = utils.filter_tests(root, position)
  if result ~= 0 then
    return {}
  end

  local command = vim.tbl_flatten({
    "ctest",
    "--test-dir " .. root .. "/build",
    "--quiet",
--    "--no-tests=ignore",
    "--output-on-failure",
    "--output-junit " .. junit_path,
    vim.tbl_flatten(args.extra_args or {}),
    vim.tbl_flatten(test_filters or {}),
  })

  return { command = command, context = { junit_path = junit_path } }
end

function CTestNeotestAdapter.results(spec, result, tree)
  local data

  with(open(spec.context.junit_path, "r"), function(reader)
    data = reader:read("*a")
  end)

  local handler = xml_tree()
  local parser = xml.parser(handler)
  parser:parse(data)

  local testcases
  if handler.root.testsuites ~= nil then
    -- Multiple testsuites
    if #handler.root.testsuites.testsuite.testcase == 0 then
      testcases = { handler.root.testsuites.testsuite.testcase }
    else
      testcases = handler.root.testsuites.testsuite.testcase
    end
  else
    -- Single testsuite
    if #handler.root.testsuite.testcase == 0 then
      testcases = { handler.root.testsuite.testcase }
    else
      testcases = handler.root.testsuite.testcase
    end
  end

  local results = {}

  for _, testcase in pairs(testcases) do
    if testcase._attr.status == "fail" then
      local message = testcase.failure._attr.message
      if message == "" then
        message = testcase["system-out"]
      end
      results[testcase._attr.name] = {
        status = "failed",
        short = message,
      }
    elseif testcase._attr.status == "disabled" then
      results[testcase._attr.name] = {
        status = "skipped",
      }
    elseif testcase._attr.status == "run" then
      results[testcase._attr.name] = {
        status = "passed",
      }
    else
      results[testcase._attr.name] = {
        status = "unknown",
      }
    end
  end

  return results
end

return CTestNeotestAdapter
