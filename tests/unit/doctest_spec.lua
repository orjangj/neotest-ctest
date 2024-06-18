local assert = require("luassert")
local doctest = require("neotest-ctest.framework.doctest")
local it = require("nio").tests.it

describe("doctest.parse_positions", function()
  it("discovers TEST_CASE macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/doctest/TEST_CASE_test.cpp"
    local actual_positions = doctest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_CASE_test.cpp",
        path = test_file,
        range = { 0, 0, 13, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "TEST_CASE"),
          name = "TEST_CASE",
          path = test_file,
          range = { 3, 0, 7, 1 },
          type = "namespace",
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST_CASE", "First"),
            name = "First",
            path = test_file,
            range = { 5, 0, 5, 37 },
            type = "test",
          },
        },
      },
      {
        {
          id = ("%s::%s"):format(test_file, "Second"),
          name = "Second",
          path = test_file,
          range = { 9, 0, 12, 1 },
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

  it("discovers TEST_CASE_FIXTURE macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/doctest/TEST_CASE_FIXTURE_test.cpp"
    local actual_positions = doctest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_CASE_FIXTURE_test.cpp",
        path = test_file,
        range = { 0, 0, 11, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "First"),
          name = "First",
          path = test_file,
          range = { 5, 0, 5, 54 },
          type = "test",
        },
      },
      {
        {
          id = ("%s::%s"):format(test_file, "Second"),
          name = "Second",
          path = test_file,
          range = { 7, 0, 10, 1 },
          type = "test",
        },
      },
    }

    assert.are.same(expected_positions[1], actual_positions[1])
    assert.are.same(expected_positions[2][1], actual_positions[2][1])
    assert.are.same(expected_positions[3][1], actual_positions[3][1])
  end)

  it("discovers SCENARIO macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/doctest/SCENARIO_test.cpp"
    local actual_positions = doctest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "SCENARIO_test.cpp",
        path = test_file,
        range = { 0, 0, 29, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "  Scenario: First"),
          name = "  Scenario: First",
          path = test_file,
          range = { 3, 0, 13, 1 },
          type = "test",
        },
      },
      {
        {
          id = ("%s::%s"):format(test_file, "  Scenario: Second"),
          name = "  Scenario: Second",
          path = test_file,
          range = { 15, 0, 28, 1 },
          type = "test",
        },
      },
    }

    assert.are.same(expected_positions[1], actual_positions[1])
    assert.are.same(expected_positions[2][1], actual_positions[2][1])
    assert.are.same(expected_positions[3][1], actual_positions[3][1])
  end)
end)

describe("doctest.parse_errors", function()
  it("parses diagnostics correctly", function()
    -- NOTE: Partial doctest output (only the relevant portions are included
    local output = [[
===============================================================================
/path/to/TEST_CASE_test.cpp:10:
TEST CASE:  Second

/path/to/TEST_CASE_test.cpp:11: ERROR: CHECK( false ) is NOT correct!
  values: CHECK( false )

/path/tp/TEST_CASE_test.cpp:12: FATAL ERROR: REQUIRE( false ) is NOT correct!
  values: REQUIRE( false )

===============================================================================
]]

    local actual_errors = doctest.parse_errors(output)
    local expected_errors = {
      {
        line = 11,
        message = "CHECK( false ) is NOT correct!\n  values: CHECK( false )",
      },
      {
        line = 12,
        message = "REQUIRE( false ) is NOT correct!\n  values: REQUIRE( false )",
      },
    }

    assert.are.same(expected_errors, actual_errors)
  end)
end)
