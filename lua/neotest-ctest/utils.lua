local logger = require("neotest.logging")
local lib = require("neotest.lib")

M = {}

-- Returns: (int: result, table: filters)
-- A non-zero result code indicates error.
-- On success, a list of filter options is returned which can be used by build_spec
-- when constructing test command.
M.filter_tests = function(root, position)
  local test_filter = {}
  local result = 0
  local name = position.name
  local type = position.type

  if type == "test" or type == "namespace" then
    test_filter[1] = "-R " .. name
  elseif type == "file" then
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

      -- input variable 'position' does not contain its children, so we'll have to generate the
      -- tree ourselves using the position path.
      local tree = require("neotest-ctest").discover_positions(position.path)

      -- Option: -I start,end,stride,test#,test#,test#,... etc
      test_filter[1] = "-I 0,0,0"
      for index, test_case in ipairs(json_info.tests) do
        -- Compare test_case.name with any of the file.namespace.test id's
        for _, namespace in ipairs(tree:children()) do
          for _, test in ipairs(namespace:children()) do
            -- NOTE: Ctest does not append the DISABLED_ prefix to its list of tests,
            -- so we'll have to remove that part so that tests prefixed with DISABLED_
            -- will get the correct neotest "skipped" sign.
            local testid = string.gsub(test:data().id, "DISABLED_", "")
            if test_case.name == testid then
              test_filter[1] = test_filter[1] .. "," .. index
            end
          end
        end
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
