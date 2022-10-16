local async = require("neotest.async")
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
  local id = position.id
  local type = position.type

  if type == "test" or type == "namespace" then
    test_filter[1] = "-R " .. id
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
  elseif type == "suite" or type == "dir" then
    -- TODO: Seems like "dirs" are the type returned when trying to run suite
    -- NOTE: No need to specify filters since we're running all tests
  else
    logger.warn(("%s: running %ss isn't supported"):format(require("neotest-ctest").name, type))
  end

  return result, test_filter
end

-- NOTE: Using key-value mapping will make it easier to remove/match ids later
M.get_tests = function(tree)
  local position = tree:data()
  local tests = { type = nil, ids = {} }

  if position.type == "test" then
    tests.type = "test"
    tests.ids[position.id] = position.id
  elseif position.type == "namespace" then
    tests.type = "namespace"
    for _, test in pairs(tree:children()) do
      tests.ids[test:data().id] = test:data().id
    end
  elseif position.type == "file" then
    tests.type = "file"
    for _, namespace in pairs(tree:children()) do
      for _, test in pairs(namespace:children()) do
        tests.ids[test:data().id] = test:data().id
      end
    end
  elseif position.type == "suite" or position.type == "dir" then
    tests.type = "suite"
    for _, file in pairs(tree:children()) do
      for _, namespace in pairs(file:children()) do
        for _, test in pairs(namespace:children()) do
          tests.ids[test:data().id] = test:data().id
        end
      end
    end
  end

  return tests
end

M.handle_testcases = function(testcases, tree)
  local results = {}
  local tests = M.get_tests(tree)

  if testcases ~= nil then
    for _, testcase in pairs(testcases) do
      local name = testcase._attr.name
      local status = testcase._attr.status

      -- remove handled testcase
      tests.ids[name] = nil

      if status == "run" then
        results[name] = { status = "passed" }
      elseif status == "fail" then
        local detailed = testcase["system-out"]
        local output = async.fn.tempname()
        local short, start_index, end_index

        _, start_index = string.find(detailed, "%[%s+RUN%s+%] ")
        end_index, _ = string.find(detailed, "%[%s+FAILED%s+%] ")
        short = string.sub(detailed, start_index + 1, end_index - 1)

        -- TODO: newlines not preserved
        vim.fn.writefile({ detailed }, output)

        results[name] = { status = "failed", short = short, output = output }
      elseif status == "disabled" then
        -- NOTE: This is a special case. Ctest does not append the DISABLED_ prefix
        -- even though the test name (as parsed by treesitter) includes it. So we'll
        -- have to handle it accordingly to get the correct neotest sign.
        local parts = vim.split(name, ".", { plain = true })
        local actual_name = parts[1] .. "." .. "DISABLED_" .. parts[2]
        results[actual_name] = { status = "skipped" }

        -- Ensure the actual id is removed
        tests.ids[actual_name] = nil
      elseif status == "skipped" then
        -- TODO: Not sure if status == "skipped" is something that ctest reports, but
        -- we check it just to be safe.
        results[name] = { status = "skipped" }
      else
        -- We should never get here... unless ctest is reporting a status that I'm not aware of.
        -- This is the best we can do until it is fixed.
        logger.error("Unable to parse unknown '" .. status .. "' status")
        results[name] = { status = "unknown" }
      end
    end
  end

  -- Handle test ids not included in testcases. This might happen if you have non-compiled tests
  -- or attempted to execute a single "disabled" test. In such cases ctest does not include them
  -- as testcases.
  for _, id in pairs(tests.ids) do
    if (string.find(id, "DISABLED_") ~= nil) and (tests.type == "test") then
      results[id] = { status = "skipped" }
    else
      results[id] = { status = "unknown" }
    end
  end

  return results
end

return M
