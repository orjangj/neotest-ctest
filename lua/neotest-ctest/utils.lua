local logger = require("neotest.logging")
local lib = require("neotest.lib")

M = {}

M.discover_tests = function(tree)
  local position = tree:data()
  local tests = {}

  if position.type == "test" then
    tests[position.id] = position.id
  else
    for _, child in pairs(tree:children()) do
      tests = vim.tbl_extend("keep", tests, M.discover_tests(child))
    end
  end

  return tests
end

M.discover_indexes = function(tree, testcases)
  local position = tree:data()
  local indexes = {}

  if position.type == "test" then
    local index = testcases[position.id]
    if index ~= nil then
      indexes[index] = index
    end
  else
    for _, child in pairs(tree:children()) do
      indexes = vim.tbl_extend("force", indexes, M.discover_indexes(child, testcases))
    end
  end

  return indexes
end

-- Returns: (int: result, table: filters)
-- A non-zero result code indicates error.
-- On success, a list of filter options is returned which can be used by build_spec
-- when constructing test command.
M.filter_tests = function(root, tree)
  local test_filter = {}
  local result = 0
  local type

  if root == tree:data().path then
    -- Neotest doesn't have a position type called suite, so we'll have to override it.
    -- Suite is the same as dir in neotest context but points to the project root directory.
    -- We need to handle suite and dirs separately since we cannot specify a dir of tests
    -- to execute to ctest.
    type = "suite"
  else
    type = tree:data().type
  end

  if type == "test" or type == "namespace" then
    test_filter[1] = "-R " .. tree:data().id
  elseif type == "file" or type == "dir" then
    -- In contrast to ctest's -R option (which is used for selecting tests by regex pattern),
    -- the -I option gives more fine-grained control as to which test to execute based on
    -- unique test indexes. However, we do not know the test indexes contained in a file
    -- apriori, so we'll have to execute a ctest dry-run command to gather information
    -- about all available tests, and then infer the test index by comparing the test
    -- name in the output with the discovered positions in the file. Note that -I option
    -- can be specified multiple times, which makes this suitible for filtering tests.
    local output
    local command = "ctest --test-dir " .. root .. "/build --show-only=json-v1"

    -- TODO: Might want to consider vim.jobstart instead. The ctest output can be quite large.
    result, output = lib.process.run({ "sh", "-c", command }, { stdout = true })

    if result == 0 then
      assert(output.stdout ~= nil, ("Got empty json response from command `%s`"):format(command))
      local json_info = vim.json.decode(output.stdout)

      local testcases = {}
      for index, test in ipairs(json_info.tests) do
        testcases[test.name] = index
      end

      -- Option: -I start,end,stride,test#,test#,test#,... etc
      test_filter[1] = "-I 0,0,0"
      local indexes = M.discover_indexes(tree, testcases)

      for _, index in pairs(indexes) do
        test_filter[1] = test_filter[1] .. "," .. index
      end
    else
      logger.error(
        ("%s: failed to run `ctest --test-dir " .. root .. "/build --show-only=json-v1`"):format(
          require("neotest-ctest").name
        )
      )
    end
  elseif type == "suite" then
    -- NOTE: No need to specify filters since we're running all tests
  else
    logger.warn(("%s: running %ss isn't supported"):format(require("neotest-ctest").name, type))
  end

  return result, test_filter
end

return M
