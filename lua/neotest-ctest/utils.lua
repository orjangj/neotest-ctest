local logger = require("neotest.logging")

M = {}

-- Returns: a list of filter options to be used by build_spec
-- TODO: Add unit test
-- TODO: Need to test for kind? I.e. TEST vs TEST_F vs TEST_P
M.filter_tests = function(root, position)
  local test_filter = {}

  if position.type == "test" then
    test_filter[#test_filter + 1] = "-R " .. position.name
  elseif position.type == "file" then
    -- In contrast to ctest's -R option (which is used for selecting tests by regex pattern),
    -- the -I option gives more fine-grained control as to which test to execute based on
    -- unique test indexes. However, we do not know the test indexes contained in a file
    -- apriori, so we'll have to execute a ctest dry-run command to gather information
    -- about all available tests, and then infer the test index by comparing the test
    -- name in the output with the discovered positions in the file. Note that -I option
    -- can be specified multiple times, which makes this suitible for filtering tests.
    -- TODO: Might want to consider vim.jobstart instead. The ctest output can be quite large.
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

return M
