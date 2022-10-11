local async = require("plenary.async.tests")
local assert = require("luassert")
local plugin = require("neotest-ctest")
local utils = require("neotest-ctest.utils")

-- TODO: WIP (not tested)

describe("neotest-ctest", function()

  local testfile = vim.loop.cwd() .. "/tests/unit/data/src/test.cpp"
  local root = vim.loop.cwd() .. "/tests/unit/data/"
  local positions = plugin.discover_positions(testfile):to_list()

  async.it("plugin.filter_tests (type=test)", function()
    local test_filter = utils.filter_tests(root, positions[2][2][1])
    local expected_filter = {"-R TestError"}
    assert.are.same(test_filter, expected_filter)
  end)

  async.it("plugin.filter_tests (type=test)", function()
    local test_filter = utils.filter_tests(root, positions[2][1])
    local expected_filter = {"-R TestFixture"}
    assert.are.same(test_filter, expected_filter)
  end)

  -- TODO
  -- Note, this actually requires running ctest dry-run command on an actual
  -- cmake project. Not sure how to handle it.
  async.it("plugin.filter_tests (type=file)", function()
    local test_filter = utils.filter_tests(root, positions[1])
    local expected_filter = {"-I 1", "-I 2", "-I 3"}
    assert.are.same(test_filter, expected_filter)
  end)

end)
