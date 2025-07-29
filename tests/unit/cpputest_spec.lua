local assert = require("luassert")
local cpputest = require("neotest-ctest.framework.cpputest")
local it = require("nio").tests.it

describe("cpputest.parse_positions", function()
  it("discovers TEST macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/cpputest/TEST_test.cpp"
    local actual_positions = cpputest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_test.cpp",
        path = test_file,
        range = { 0, 0, 14, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "TEST"),
          name = "TEST",
          path = test_file,
          range = { 2, 0, 13, 1 },
          type = "namespace",
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST", "Suite.First"),
            name = "Suite.First",
            path = test_file,
            range = { 6, 0, 6, 35 },
            type = "test",
          },
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST", "Suite.Second"),
            name = "Suite.Second",
            path = test_file,
            range = { 8, 0, 11, 1 },
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

describe("cpputest.parse_errors", function()
  it("parses diagnostics correctly", function()
    -- NOTE: Partial cpputest output (only the relevant portions are included)
    local output = [[
TEST(Suite, First)
/path/to/TEST_test.cpp:10: error: Failure in TEST(Suite, First)
    expected &lt;2&gt;
    but was  &lt;1&gt;
    difference starts at position 0 at: &lt;          1         &gt;
                                                   ^

 - 1 ms

Errors (1 failures, 4 tests, 1 ran, 1 checks, 0 ignored, 3 filtered out, 1 ms)
]]

    local actual_errors = cpputest.parse_errors(output)
    local expected_errors = {
      {
        line = 10,
        message = [[
    expected &lt;2&gt;
    but was  &lt;1&gt;
    difference starts at position 0 at: &lt;          1         &gt;
                                                   ^]],
      },
    }

    assert.are.same(expected_errors, actual_errors)
  end)
end)
