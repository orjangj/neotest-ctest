local assert = require("luassert")
local gtest = require("neotest-ctest.framework.gtest")
local it = require("nio").tests.it

-- TODO: Mock lib.files.read()?

describe("gtest.parse_positions", function()
  it("discovers TEST macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/gtest/TEST_test.cpp"
    local actual_positions = gtest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_test.cpp",
        path = test_file,
        range = { 0, 0, 12, 0 },
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
            name = "Suite.Second",
            path = test_file,
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

  it("discovers TEST_F macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/gtest/TEST_F_test.cpp"
    local actual_positions = gtest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_F_test.cpp",
        path = test_file,
        range = { 0, 0, 14, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "TEST_F"),
          name = "TEST_F",
          path = test_file,
          range = { 2, 0, 13, 1 },
          type = "namespace",
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST_F", "Fixture.First"),
            name = "Fixture.First",
            path = test_file,
            range = { 6, 0, 6, 45 },
            type = "test",
          },
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "TEST_F", "Fixture.Second"),
            name = "Fixture.Second",
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

  it("discovers TEST_P macro", function()
    local test_file = vim.loop.cwd() .. "/tests/unit/data/gtest/TEST_P_test.cpp"
    local actual_positions = gtest.parse_positions(test_file):to_list()
    local expected_positions = {
      {
        id = test_file,
        name = "TEST_P_test.cpp",
        path = test_file,
        range = { 0, 0, 14, 0 },
        type = "file",
      },
      {
        {
          id = ("%s::%s"):format(test_file, "ParameterizedBool.Test"),
          name = "ParameterizedBool.Test",
          path = test_file,
          range = { 4, 0, 4, 64 },
          type = "namespace",
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "ParameterizedBool.Test", "P1/ParameterizedBool.Test/false"),
            name = "P1/ParameterizedBool.Test/false",
            path = test_file,
            type = "test",
          },
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "ParameterizedBool.Test", "P1/ParameterizedBool.Test/true"),
            name = "P1/ParameterizedBool.Test/true",
            path = test_file,
            type = "test",
          },
        },
      },
      {
        {
          id = ("%s::%s"):format(test_file, "ParameterizedInt.Test"),
          name = "ParameterizedInt.Test",
          path = test_file,
          range = { 10, 0, 10, 60 },
          type = "namespace",
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "ParameterizedInt.Test", "P1/ParameterizedInt.Test/0"),
            name = "P1/ParameterizedInt.Test/0",
            path = test_file,
            type = "test",
          },
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "ParameterizedInt.Test", "P1/ParameterizedInt.Test/1"),
            name = "P1/ParameterizedInt.Test/1",
            path = test_file,
            type = "test",
          },
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "ParameterizedInt.Test", "P1/ParameterizedInt.Test/2"),
            name = "P1/ParameterizedInt.Test/2",
            path = test_file,
            type = "test",
          },
        },
        {
          {
            id = ("%s::%s::%s"):format(test_file, "ParameterizedInt.Test", "P1/ParameterizedInt.Test/3"),
            name = "P1/ParameterizedInt.Test/3",
            path = test_file,
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
    assert.are.same(expected_positions[3][1], actual_positions[3][1])
    assert.are.same(expected_positions[3][2][1], actual_positions[3][2][1])
    assert.are.same(expected_positions[3][3][1], actual_positions[3][3][1])
    assert.are.same(expected_positions[3][4][1], actual_positions[3][4][1])
    assert.are.same(expected_positions[3][5][1], actual_positions[3][5][1])
  end)
end)

describe("gtest.parse_errors", function()
  it("parses gtest >= v1.14.0 diagnostics correctly", function()
    -- NOTE: Partial GTest output (only the relevant portions are included)
    local output = [[
[ RUN      ] Suite.Second
/path/to/TEST_test.cpp:8: Failure
Value of: false
  Actual: false
Expected: true

/path/to/TEST_test.cpp:9: Failure
Value of: false
  Actual: false
Expected: true

[  FAILED  ] Suite.Second (0 ms)
]]

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

  it("parses gtest < v1.14.0 diagnostics correctly", function()
    -- NOTE: Partial GTest output (only the relevant portions are included)
    local output = [[
[ RUN      ] Suite.Second
/path/to/TEST_test.cpp:8: Failure
Value of: false
  Actual: false
Expected: true
/path/to/TEST_test.cpp:9: Failure
Value of: false
  Actual: false
Expected: true
[  FAILED  ] Suite.Second (0 ms)
]]

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
