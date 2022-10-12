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
    -- Different naming conventions
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

    -- NOTE: ranges are zero indexed
    -- range = { row start pos, column start pos, row end pos, column end pos}
    -- For files, only the number of lines of code are necessary { 0, 0, x, 0 }
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
          id = "TestFixture",
          name = "TestFixture",
          path = testfile,
          range = { 10, 0, 23, 1 },
          type = "namespace",
        },
        {
          {
            id = "TestFixture.TestError",
            name = "TestError",
            path = testfile,
            range = { 10, 0, 13, 1 },
            type = "test",
          },
        },
        {
          {
            id = "TestFixture.TestOk",
            name = "TestOk",
            path = testfile,
            range = { 15, 0, 18, 1 },
            type = "test",
          },
        },
        {
          {
            id = "TestFixture.FailInFixture",
            name = "FailInFixture",
            path = testfile,
            range = { 20, 0, 23, 1 },
            type = "test",
          },
        },
      },
    }

    -- The results are difficult to debug if we do not split the assertions
    assert.are.same(expected_positions[1], positions[1])
    assert.are.same(expected_positions[2][1], positions[2][1])
    assert.are.same(expected_positions[2][2][1], positions[2][2][1])
    assert.are.same(expected_positions[2][3][1], positions[2][3][1])
    assert.are.same(expected_positions[2][4][1], positions[2][4][1])
  end)


  async.it("plugin.results", function()
    local spec = { context = { junit_path = vim.loop.cwd() .. "/tests/unit/data/tests.junit.xml" } }
    local results = plugin.results(spec)

    local expected = {
      ["TestFixture.TestError"] = {
        status = "failed",
        short = [[Running main() from neotest-ctest/tests/integration/build/_deps/googletest-src/googletest/src/gtest_main.cc
Note: Google Test filter = TestFixture.TestError
[==========] Running 1 test from 1 test suite.
[----------] Global test environment set-up.
[----------] 1 test from TestFixture
[ RUN      ] TestFixture.TestError
neotest-ctest/tests/integration/src/test.cpp:13: Failure
Value of: false
  Actual: false
Expected: true
[  FAILED  ] TestFixture.TestError (0 ms)
[----------] 1 test from TestFixture (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test suite ran. (0 ms total)
[  PASSED  ] 0 tests.
[  FAILED  ] 1 test, listed below:
[  FAILED  ] TestFixture.TestError

 1 FAILED TEST]]
      },
      ["TestFixture.TestOk"] = {
        status = "passed",
      },
      ["TestFixture.FailInFixture"] = {
        status = "failed",
        short = [[Running main() from neotest-ctest/tests/integration/build/_deps/googletest-src/googletest/src/gtest_main.cc
Note: Google Test filter = TestFixture.FailInFixture
[==========] Running 1 test from 1 test suite.
[----------] Global test environment set-up.
[----------] 1 test from TestFixture
[ RUN      ] TestFixture.FailInFixture
neotest-ctest/tests/integration/src/test.cpp:8: Failure
Value of: false
  Actual: false
Expected: true
[  FAILED  ] TestFixture.FailInFixture (0 ms)
[----------] 1 test from TestFixture (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test suite ran. (0 ms total)
[  PASSED  ] 0 tests.
[  FAILED  ] 1 test, listed below:
[  FAILED  ] TestFixture.FailInFixture

 1 FAILED TEST]]
      }
    }

    assert.are.same(expected, results)
  end)
end)
