local async = require("neotest.async")
local lib = require("neotest.lib")
local Path = require("plenary.path")
local xml = require("neotest.lib.xml")
local xml_tree = require("neotest.lib.xml.tree")
local utils = require("neotest-ctest.utils")

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

  local test_filters = utils.filter_tests(root, position)

  local command = vim.tbl_flatten({
    "ctest",
    "--test-dir " .. root .. "/build", -- TODO: Allow configurable build path?
    "--quiet", -- Do not print to console (only to junit_path)
    "--no-tests=ignore", -- If no tests are found, then ctest will not return an error
    "--output-on-failure",
    "--output-junit " .. junit_path,
    vim.tbl_flatten(args.extra_args or {}),
    vim.tbl_flatten(test_filters or {}),
  })

  return { command = command, context = { junit_path = junit_path } }
end

function CTestNeotestAdapter.results(spec, result)
  local data

  with(open(spec.context.junit_path, "r"), function(reader)
    data = reader:read("*a")
  end)

  local handler = xml_tree:new()
  local xml_parser = xml.parser(handler)
  xml_parser:parse(data)

  -- TODO: Not sure the XML tree here (copy-pasted from neotest-rust) is the same structure as
  -- ctest uses. Will have to test I guess.
  local testcases
  if #handler.root.testsuites.testsuite.testcase == 0 then
    testcases = { handler.root.testsuites.testsuite.testcase }
  else
    testcases = handler.root.testsuites.testsuite.testcase
  end

  local results = {}

  for _, testcase in pairs(testcases) do
    -- status = one of 'run', 'fail', 'disabled', where run=success and disabled=skipped
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

  return results
end

return CTestNeotestAdapter
