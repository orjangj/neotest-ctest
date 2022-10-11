local async = require("plenary.async.tests")
local assert = require("luassert")
local mock = require("luassert.mock")
local plugin = require("neotest-ctest")
local utils = require("neotest-ctest.utils")

-- TODO: WIP (not tested)

describe("neotest-ctest", function()
  async.it("plugin.filter_tests (type=test)", function()
    local testfile = vim.loop.cwd() .. "/tests/unit/data/src/test.cpp"
    local root = vim.loop.cwd() .. "/tests/unit/data/"
    local tree = plugin.discover_positions(testfile)
    local result, test_filter = utils.filter_tests(root, tree:children()[1]:children()[1])

    assert.equals(result, 0)

    local expected_filter = { "-R TestError" }
    assert.are.same(test_filter, expected_filter)
  end)

  async.it("plugin.filter_tests (type=namespace)", function()
    local testfile = vim.loop.cwd() .. "/tests/unit/data/src/test.cpp"
    local root = vim.loop.cwd() .. "/tests/unit/data/"
    local tree = plugin.discover_positions(testfile)
    local result, test_filter = utils.filter_tests(root, tree:children()[1])

    assert.equals(result, 0)

    local expected_filter = { "-R TestFixture" }
    assert.are.same(test_filter, expected_filter)
  end)

  -- TODO: Need to mock underlying call to require("neotest.lib").process.run()
  -- This function call should instead return the preformatted ctestinfo.json
  async.it("plugin.filter_tests (type=file)", function()
    local testfile = vim.loop.cwd() .. "/tests/unit/data/src/test.cpp"
    local root = vim.loop.cwd() .. "/tests/integration"
    local tree = plugin.discover_positions(testfile)
    local result, test_filter = utils.filter_tests(root, tree)

    assert.equals(result, 0)

    local expected_filter = { "-I 1", "-I 2", "-I 3" }
    assert.are.same(expected_filter, test_filter)
  end)
end)
