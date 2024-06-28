local assert = require("luassert")
local adapter = require("neotest-ctest")
local config = require("neotest-ctest.config")

local user_config = {
  root = function(_)
    return true
  end,
  is_test_file = function(_)
    -- All files are reported as test files
    return true
  end,
  filter_dir = function(_, _, _)
    -- Don't filter anything
    return true
  end,
  frameworks = { "gtest" },
  extra_args = { "--schedule-random" },
}

adapter.setup(user_config)

describe("adapter.setup", function()
  it("should initialize user config", function()
    local expected_config = user_config
    local actual_config = config.get()
    assert.are.same(expected_config.root, actual_config.root)
    assert.are.same(expected_config.is_test_file, actual_config.is_test_file)
    assert.are.same(expected_config.filter_dir, actual_config.filter_dir)
    assert.are.same(expected_config.frameworks, actual_config.frameworks)
    assert.are.same(expected_config.extra_args, actual_config.extra_args)
  end)
end)

describe("adapter.root", function()
  it("should call user implementation", function()
    -- This would fail with an error otherwise due to non-existent directory
    assert.is_true(adapter.root("/foo"))
  end)
end)

describe("adapter.is_test_file", function()
  it("should call user implementation", function()
    -- This would return false for default config
    assert.is_true(adapter.is_test_file("/foo/bar.cc"))
  end)
end)

describe("adapter.filter_dir", function()
  it("should call user implementation", function()
    -- This would return false for default config
    assert.is_true(adapter.filter_dir("build", "", ""))
  end)
end)
