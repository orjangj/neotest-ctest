local assert = require("luassert")
local catch2 = require("neotest-ctest.framework.catch2")
local it = require("nio").tests.it

describe("catch2.parse_positions", function()
  it("discovers TEST_CASE macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/catch2/TEST_CASE_test.cpp"
    local actual_positions = catch2.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_CASE_test.cpp",
        path = test_file,
        range = { 0, 0, 12, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "TEST_CASE"),
          name = "TEST_CASE",
          path = test_file,
          range = { 2, 0, 6, 1 },
          type = "namespace",
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST_CASE", "First"),
            name = "First",
            path = test_file,
            range = { 4, 0, 4, 48 },
            type = "test",
          },
        },
      },
      {
        {
          id = ("%s::%s"):format(test_file, "Second"),
          name = "Second",
          path = test_file,
          range = { 8, 0, 11, 1 },
          type = "test",
        },
      },
    }

    -- NOTE: assert.are.same() crops the output when table is too deep.
    -- Splitting the assertions for increased readability in case of failure.
    assert.are.same(expected_positions[1], actual_positions[1])
    assert.are.same(expected_positions[2][1], actual_positions[2][1])
    assert.are.same(expected_positions[2][2][1], actual_positions[2][2][1])
    assert.are.same(expected_positions[3][1], actual_positions[3][1])
  end)

  it("discovers TEST_CASE_METHOD macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/catch2/TEST_CASE_METHOD_test.cpp"
    local actual_positions = catch2.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_CASE_METHOD_test.cpp",
        path = test_file,
        range = { 0, 0, 10, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "First"),
          name = "First",
          path = test_file,
          range = { 4, 0, 4, 64 },
          type = "test",
        },
      },
      {
        {
          id = ("%s::%s"):format(test_file, "Second"),
          name = "Second",
          path = test_file,
          range = { 6, 0, 9, 1 },
          type = "test",
        },
      },
    }

    assert.are.same(expected_positions[1], actual_positions[1])
    assert.are.same(expected_positions[2][1], actual_positions[2][1])
    assert.are.same(expected_positions[3][1], actual_positions[3][1])
  end)

  it("discovers SCENARIO macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/catch2/SCENARIO_test.cpp"
    local actual_positions = catch2.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "SCENARIO_test.cpp",
        path = test_file,
        range = { 0, 0, 28, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "Scenario: First"),
          name = "Scenario: First",
          path = test_file,
          range = { 2, 0, 12, 1 },
          type = "test",
        },
      },
      {
        {
          id = ("%s::%s"):format(test_file, "Scenario: Second"),
          name = "Scenario: Second",
          path = test_file,
          range = { 14, 0, 27, 1 },
          type = "test",
        },
      },
    }

    assert.are.same(expected_positions[1], actual_positions[1])
    assert.are.same(expected_positions[2][1], actual_positions[2][1])
    assert.are.same(expected_positions[3][1], actual_positions[3][1])
  end)
end)

describe("catch2.parse_errors", function()
  it("parses diagnostics correctly", function()
    -- NOTE: Partial catch2 output (only the relevant portions are included
    local output = [[
Filters: "Second"
Randomness seeded to: 2250342149

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
catch2_test is a Catch2 v3.3.0 host application.
Run with -? for options

-------------------------------------------------------------------------------
Second
-------------------------------------------------------------------------------
/path/to/TEST_CASE_test.cpp:5
...............................................................................

/path/to/TEST_CASE_test.cpp:6: FAILED:
  CHECK( false )

/path/to/TEST_CASE_test.cpp:7: FAILED:
  REQUIRE( false )

===============================================================================
test cases: 1 | 1 failed
assertions: 2 | 2 failed
]]

    local actual_errors = catch2.parse_errors(output)
    local expected_errors = {
      {
        line = 6,
        message = "CHECK( false )",
      },
      {
        line = 7,
        message = "REQUIRE( false )",
      },
    }

    assert.are.same(expected_errors, actual_errors)
  end)
end)
