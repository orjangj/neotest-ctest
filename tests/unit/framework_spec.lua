local assert = require("luassert")
local stub = require("luassert.stub")
local framework = require("neotest-ctest.framework")
local it = require("nio").tests.it
local lib = require("neotest.lib")

describe("framework.detect", function()
  local ignore_arg = ""
  stub(lib.files, "read")

  it("should discover catch2 framework", function()
    local expected = require("neotest-ctest.framework.catch2")

    lib.files.read.returns("#include <catch2/catch_test_macros.hpp>")
    local actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)

    lib.files.read.returns("#include \"catch2/catch_test_macros.hpp\"")
    actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)
  end)

  it("should discover doctest framework", function()
    local expected = require("neotest-ctest.framework.doctest")

    lib.files.read.returns("#include <doctest/doctest.h>")
    local actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)

    lib.files.read.returns("#include <doctest.h>")
    actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)

    lib.files.read.returns("#include \"doctest/doctest.h\"")
    actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)

    lib.files.read.returns("#include \"doctest.h\"")
    actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)
  end)

  it("should discover gtest framework", function()
    local expected = require("neotest-ctest.framework.gtest")

    lib.files.read.returns("#include <gtest/gtest.h>")
    local actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)

    lib.files.read.returns("#include <gtest.h>")
    actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)

    lib.files.read.returns("#include \"gtest/gtest.h\"")
    actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)

    lib.files.read.returns("#include \"gtest.h\"")
    actual = framework.detect(ignore_arg)
    assert.are.same(expected, actual)
  end)
end)
