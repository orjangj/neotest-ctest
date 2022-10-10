local async = require("neotest.async")
local lib = require("neotest.lib")
local logger = require("neotest.logging")
local Path = require("plenary.path")
local xml = require("neotest.lib.xml")
local xml_tree = require("neotest.lib.xml.tree")

local CTestNeotestAdapter = { name = "neotest-ctest" }

-- TODO: Are these patterns enough?
CTestNeotestAdapter.root = lib.files.match_root_pattern("build", "CMakeLists.txt", ".git")

-- Returns: a list of filter options to be used by build_spec
-- TODO: Add unit test
-- TODO: Need to test for kind? I.e. TEST vs TEST_F vs TEST_P
local filter_tests = function(position)
  local test_filter = {}

  if position.type == "test" then
    test_filter[#test_filter+1] = "-R " .. position.name
  elseif position.type == "file" then
    -- In contrast to ctest's -R option (which is used for selecting tests by regex pattern),
    -- the -I option gives more fine-grained control as to which test to execute based on
    -- unique test indexes. However, we do not know the test indexes contained in a file
    -- apriori, so we'll have to execute a ctest dry-run command to gather information
    -- about all available tests, and then infer the test index by comparing the test
    -- name in the output with the discovered positions in the file. Note that -I option
    -- can be specified multiple times, which makes this suitible for filtering tests.
    -- TODO: Might want to consider vim.jobstart instead. The ctest output can be quite large.
    local root = CTestNeotestAdapter.root(position.path)
    local result, output = lib.process.run("ctest", {
      "--test-dir " .. root .. "/build",
      "--show-only=json-v1",
    })

    if result ~= 0 then
      print(result, output.stdout, output.stderr) -- raise error/warning instead?
      return {}
    end

    local json_info = vim.json.decode(output.stdout)

    for index, test in ipairs(json_info.tests) do
      local parts = vim.fn.split(position.id, "::")
      local posid = parts[1] .. "." .. parts[2]
      if test.name == posid then
        test_filter[#test_filter + 1] = "-I " .. index
      end
    end
  elseif position.type == "suite" then
    -- NOTE: No need to specify filters since we're running all tests
  else
    logger.warn(("%s doesn't support running %ss"):format(CTestNeotestAdapter.name, position.type))
  end

  return test_filter
end

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

  return lib.treesitter.parse_positions(path, query)
end

function CTestNeotestAdapter.build_spec(args)
  -- TODO: Unit tests
  local position = args.tree:data()
  local path = position.path
  local root = CTestNeotestAdapter.root(path)
  local junit_path = async.fn.tempname() .. ".junit.xml"

  local test_filters = filter_tests(position)

  local command = {
    "ctest",
    "--test-dir " .. root .. "/build",
    "--quiet", -- Do not print to console (only to junit_path)
    --    "--not-tests=ignore",  -- If no tests are found, then ctest will not return an error
    "--output-on-failure",
    "--output-junit " .. junit_path,
  }

  if args.extra_args then
    command = vim.tbl_extend("keep", command, args.extra_args)
  end
  if test_filters then
    command = vim.tbl_extend("keep", command, test_filters)
  end

  command = vim.tbl_flatten(command)

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
