local assert = require("luassert")
local it = require("nio.tests").it
local before_each = require("nio.tests").before_each
local Path = require("plenary.path")

describe("with project root", function()
  local example_root, ctest

  before_each(function()
    local cwd = vim.loop.cwd()
    example_root = cwd .. "/tests/integration/example"
    ctest = require("neotest-ctest.ctest"):new(example_root)
  end)

  it("CTest test directory is found", function()
    local expected_test_dir = Path:new(example_root, "build"):absolute()
    assert.equals(expected_test_dir, ctest._test_dir)
  end)

  it("CTest tests are found", function()
    -- NOTE: If we did an exact match of expected number of test cases vs actual number of test cases,
    -- we would have to update *this* test every time we added new test cases to the example project.
    -- That would be painful to maintain... so let's be pragmatic.

    local testcases = ctest:testcases()
    local num_testcases = #vim.tbl_keys(testcases)
    assert.is_true(num_testcases > 0)
  end)
end)
