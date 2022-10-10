local async = require("plenary.async.tests")
local assert = require("luassert")
local plugin = require("neotest-ctest")

describe("neotest-ctest", function()
  async.it("plugin.name", function()
    assert.equals("neotest-ctest", plugin.name)
  end)

  async.it("plugin.is_test_file", function()
    -- Positive test cases
    -- File extensions
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.C"))
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.cc"))
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.cpp"))
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.CPP"))
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.c++"))
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.cp"))
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.cxx"))
    -- Keywords test and Test
    assert.is_true(plugin.is_test_file("foo/bar/test_foo.cpp"))
    assert.is_true(plugin.is_test_file("foo/bar/Test_foo.cpp"))
    -- Different fiing conventions
    assert.is_true(plugin.is_test_file("foo/bar/test.foo.cpp"))
    assert.is_true(plugin.is_test_file("foo/bar/foo.Test.cpp"))
    assert.is_true(plugin.is_test_file("foo/bar/fooTest.cpp"))
    assert.is_true(plugin.is_test_file("foo/bar/testFoo.cpp"))

    -- Negative test cases (not test files)
    assert.is_false(plugin.is_test_file("foo/bar/other.cpp"))
    assert.is_false(plugin.is_test_file("foo/bar/no_extension"))
    assert.is_false(plugin.is_test_file("foo/bar/directory/"))
  end)

  async.it("plugin.discover_positions", function()
    local testfile = vim.loop.cwd() .. "/tests/unit/data/src/test.cpp"
    local positions = plugin.discover_positions(testfile):to_list()

    local expected_positions = {
      {
        id = testfile,
        name = "test.cpp",
        path = testfile,
        range = { 0, 0, 26, 0 },
        type = "file",
      },
      {
        {
          id = "TestFixture::TestError",
          name = "TestError",
          path = testfile,
          range = { 18, 4, 23, 5 },
          type = "test",
        },
        {
          id = "TestFixture::TestOk",
          name = "TestOk",
          path = testfile,
          range = { 20, 8, 22, 9 },
          type = "test",
        },
        {
          id = "TestFixture::FailInFixture",
          name = "FailInFixture",
          path = testfile,
          range = { 20, 8, 22, 9 },
          type = "test",
        },
      },
    }

    assert.are.same(positions, expected_positions)
  end)
end)
