local async = require("plenary.async.tests")
local luassert = require("luassert")
local adapter = require("neotest-ctest")

describe("neotest-ctest", function()
  async.it("plugin.name", function()
    luassert.equals("neotest-ctest", adapter.name)
  end)

  async.it("plugin.root (pattern)", function()
    local root = adapter.root(vim.loop.cwd() .. "/tests/integration")
    luassert.are.same(vim.loop.cwd() .. "/tests/integration", root)
  end)

  async.it("plugin.is_test_file", function()
    -- Positive test cases
    -- File extensions
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.C"))
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.cc"))
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.cpp"))
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.CPP"))
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.c++"))
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.cp"))
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.cxx"))
    -- Keywords test and Test
    luassert.is_true(adapter.is_test_file("foo/bar/test_foo.cpp"))
    luassert.is_true(adapter.is_test_file("foo/bar/Test_foo.cpp"))
    -- Different naming conventions
    luassert.is_true(adapter.is_test_file("foo/bar/test.foo.cpp"))
    luassert.is_true(adapter.is_test_file("foo/bar/foo.Test.cpp"))
    luassert.is_true(adapter.is_test_file("foo/bar/fooTest.cpp"))
    luassert.is_true(adapter.is_test_file("foo/bar/testFoo.cpp"))
    -- Negative test cases (not test files)
    luassert.is_false(adapter.is_test_file("foo/bar/other.cpp"))
    luassert.is_false(adapter.is_test_file("foo/bar/no_extension"))
    luassert.is_false(adapter.is_test_file("foo/bar/directory/"))
  end)

  async.it("plugin.discover_positions", function()
    local testfile = vim.loop.cwd() .. "/tests/unit/data/src/test.cpp"
    local positions = adapter.discover_positions(testfile):to_list()

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
    luassert.are.same(expected_positions[1], positions[1])
    luassert.are.same(expected_positions[2][1], positions[2][1])
    luassert.are.same(expected_positions[2][2][1], positions[2][2][1])
    luassert.are.same(expected_positions[2][3][1], positions[2][3][1])
    luassert.are.same(expected_positions[2][4][1], positions[2][4][1])
  end)

  async.it("plugin.results", function()
    local spec = { context = { junit_path = vim.loop.cwd() .. "/tests/unit/data/tests.junit.xml" } }
    local results = adapter.results(spec)

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

 1 FAILED TEST]],
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

 1 FAILED TEST]],
      },
    }

    luassert.are.same(expected, results)
  end)
end)
