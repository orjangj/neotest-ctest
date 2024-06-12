local assert = require("luassert")
local gtest = require("neotest-ctest.framework.gtest")
local it = require("nio").tests.it

describe("neotest-ctest.framework.gtest.parse_positions", function()
  it("discovers TEST macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/gtest/gtest_test.cpp"
    local actual_positions = gtest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "gtest_test.cpp",
        path = test_file,
        range = { 0, 0, 25, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "TEST"),
          name = "TEST",
          path = test_file,
          range = { 2, 0, 11, 1 },
          type = "namespace",
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST", "Suite.First"),
            name = "Suite.First",
            path = test_file,
            range = { 4, 0, 4, 41 },
            type = "test",
          },
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST", "Suite.Second"),
            name = "Suite.Second", path = test_file,
            range = { 6, 0, 9, 1 },
            type = "test",
          },
        },
      },
    }

    -- NOTE: assert.are.same() crops the output when table is too deep.
    -- Splitting the assertions for increased readability in case of failure.
    assert.are.same(expected_positions[1], actual_positions[1])
    assert.are.same(expected_positions[2][1], actual_positions[2][1])
    assert.are.same(expected_positions[2][2][1], actual_positions[2][2][1])
    assert.are.same(expected_positions[2][3][1], actual_positions[2][3][1])
  end)
end)

describe("neotest-ctest.framework.gtest.parse_errors", function ()

  local blob = [[
Running main() from /path/to/gtest_main.cc
Note: Google Test filter = Suite.Second
[==========] Running 1 test from 1 test suite.
[----------] Global test environment set-up.
[----------] 1 test from Suite
[ RUN      ] Suite.Second
%s
[  FAILED  ] Suite.Second (0 ms)
[----------] 1 test from Suite (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test suite ran. (0 ms total)
[  PASSED  ] 0 tests.
[  FAILED  ] 1 test, listed below:
[  FAILED  ] Suite.Second

 1 FAILED TEST
  ]]

  it("parses gtest >= v1.14.0 diagnostics correctly", function ()
    local output = blob:format([[
/path/to/gtest_test.cpp:8: Failure
Value of: false
  Actual: false
Expected: true

/path/to/gtest_test.cpp:9: Failure
Value of: false
  Actual: false
Expected: true

    ]])

    local actual_errors = gtest.parse_errors(output)
    local expected_errors = {
      {
        line = 8,
        message = "Value of: false\n  Actual: false\nExpected: true",
      },
      {
        line = 9,
        message = "Value of: false\n  Actual: false\nExpected: true",
      },
    }

    assert.are.same(expected_errors, actual_errors)
  end)

  it("parses gtest < v1.14.0 diagnostics correctly", function ()
    local output = blob:format([[
/path/to/gtest_test.cpp:8: Failure
Value of: false
  Actual: false
Expected: true
/path/to/gtest_test.cpp:9: Failure
Value of: false
  Actual: false
Expected: true
    ]])

    local actual_errors = gtest.parse_errors(output)
    local expected_errors = {
      {
        line = 8,
        message = "Value of: false\n  Actual: false\nExpected: true",
      },
      {
        line = 9,
        message = "Value of: false\n  Actual: false\nExpected: true",
      },
    }

    assert.are.same(expected_errors, actual_errors)
  end)
end)
