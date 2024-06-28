local assert = require("luassert")
local nio = require("nio")
local it = nio.tests.it
local before_each = nio.tests.before_each
local utils = require("tests.integration.utils")

describe("with TEST macro", function()
  local state, test_file

  before_each(function()
    state = utils.setup()
    test_file = state.example_root .. "/gtest/TEST_test.cpp"
  end)

  it("run single test", function()
    local id = utils.make_neotest_id(test_file, { name = "GoogleTest.Ok" })

    state.neotest.run.run(id)

    local results = state.client:get_results(state.adapter_id)

    assert.equals("passed", results[id].status)
  end)

  it("run multiple tests", function()
    local id = utils.make_neotest_id(test_file)
    local test_ok_id = utils.make_neotest_id(test_file, { name = "GoogleTest.Ok" })
    local test_fail_id = utils.make_neotest_id(test_file, { name = "GoogleTest.Fail" })

    state.neotest.run.run(id)

    local results = state.client:get_results(state.adapter_id)

    assert.equals("failed", results[id].status)
    assert.equals("passed", results[test_ok_id].status)
    assert.equals("failed", results[test_fail_id].status)
  end)
end)

describe("with TEST_F macro", function()
  local state, test_file

  before_each(function()
    state = utils.setup()
    test_file = state.example_root .. "/gtest/TEST_F_test.cpp"
  end)

  it("run single test", function()
    local id = utils.make_neotest_id(test_file, { name = "GoogleTest.Ok" })

    state.neotest.run.run(id)

    local results = state.client:get_results(state.adapter_id)

    assert.equals("passed", results[id].status)
  end)

  it("run multiple tests", function()
    local id = utils.make_neotest_id(test_file)
    local test_ok_id = utils.make_neotest_id(test_file, { name = "GoogleTest.Ok" })
    local test_fail_id = utils.make_neotest_id(test_file, { name = "GoogleTest.Fail" })

    state.neotest.run.run(id)

    local results = state.client:get_results(state.adapter_id)

    assert.equals("failed", results[id].status)
    assert.equals("passed", results[test_ok_id].status)
    assert.equals("failed", results[test_fail_id].status)
  end)
end)

describe("with TEST_P macro", function()
  local state, test_file

  before_each(function()
    state = utils.setup()
    test_file = state.example_root .. "/gtest/TEST_P_test.cpp"
  end)

  describe("Bool parameter generator", function()
    it("run single parameter", function()
      local id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedBool.Test", name = "GoogleTest/ParameterizedBool.Test/true" }
      )

      state.neotest.run.run(id)

      local results = state.client:get_results(state.adapter_id)

      assert.equals("passed", results[id].status)
    end)

    it("run all parameters", function()
      local id = utils.make_neotest_id(test_file, { name = "ParameterizedBool.Test" })
      local true_id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedBool.Test", name = "GoogleTest/ParameterizedBool.Test/true" }
      )
      local false_id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedBool.Test", name = "GoogleTest/ParameterizedBool.Test/false" }
      )

      state.neotest.run.run(id)

      local results = state.client:get_results(state.adapter_id)

      assert.equals("failed", results[id].status)
      assert.equals("passed", results[true_id].status)
      assert.equals("failed", results[false_id].status)
    end)
  end)

  describe("Range parameter generator", function()
    it("run single parameter", function()
      local id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedRange.Test", name = "GoogleTest/ParameterizedRange.Test/0" }
      )

      state.neotest.run.run(id)

      local results = state.client:get_results(state.adapter_id)

      assert.equals("passed", results[id].status)
    end)

    it("run all parameters", function()
      local id = utils.make_neotest_id(test_file, { name = "ParameterizedRange.Test" })
      local zero_id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedRange.Test", name = "GoogleTest/ParameterizedRange.Test/0" }
      )
      local one_id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedRange.Test", name = "GoogleTest/ParameterizedRange.Test/1" }
      )

      state.neotest.run.run(id)

      local results = state.client:get_results(state.adapter_id)

      assert.equals("failed", results[id].status)
      assert.equals("passed", results[zero_id].status)
      assert.equals("failed", results[one_id].status)
    end)
  end)

  describe("Values parameter generator", function()
    it("run single parameter", function()
      local id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedValues.Test", name = "GoogleTest/ParameterizedValues.Test/0" }
      )

      state.neotest.run.run(id)

      local results = state.client:get_results(state.adapter_id)

      assert.equals("passed", results[id].status)
    end)

    it("run all parameters", function()
      local id = utils.make_neotest_id(test_file, { name = "ParameterizedValues.Test" })
      local zero_id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedValues.Test", name = "GoogleTest/ParameterizedValues.Test/0" }
      )
      local one_id = utils.make_neotest_id(
        test_file,
        { namespace = "ParameterizedValues.Test", name = "GoogleTest/ParameterizedValues.Test/1" }
      )

      state.neotest.run.run(id)

      local results = state.client:get_results(state.adapter_id)

      assert.equals("failed", results[id].status)
      assert.equals("passed", results[zero_id].status)
      assert.equals("failed", results[one_id].status)
    end)
  end)

  it("run multiple parameterized tests", function()
    local id = utils.make_neotest_id(test_file)

    local bool_true_id = utils.make_neotest_id(
      test_file,
      { namespace = "ParameterizedBool.Test", name = "GoogleTest/ParameterizedBool.Test/true" }
    )
    local bool_false_id = utils.make_neotest_id(
      test_file,
      { namespace = "ParameterizedBool.Test", name = "GoogleTest/ParameterizedBool.Test/false" }
    )
    local range_zero_id = utils.make_neotest_id(
      test_file,
      { namespace = "ParameterizedRange.Test", name = "GoogleTest/ParameterizedRange.Test/0" }
    )
    local range_one_id = utils.make_neotest_id(
      test_file,
      { namespace = "ParameterizedRange.Test", name = "GoogleTest/ParameterizedRange.Test/1" }
    )
    local values_zero_id = utils.make_neotest_id(
      test_file,
      { namespace = "ParameterizedValues.Test", name = "GoogleTest/ParameterizedValues.Test/0" }
    )
    local values_one_id = utils.make_neotest_id(
      test_file,
      { namespace = "ParameterizedValues.Test", name = "GoogleTest/ParameterizedValues.Test/1" }
    )

    state.neotest.run.run(id)

    local results = state.client:get_results(state.adapter_id)

    assert.equals("failed", results[id].status)
    assert.equals("passed", results[bool_true_id].status)
    assert.equals("failed", results[bool_false_id].status)
    assert.equals("passed", results[range_zero_id].status)
    assert.equals("failed", results[range_one_id].status)
    assert.equals("passed", results[values_zero_id].status)
    assert.equals("failed", results[values_one_id].status)
  end)
end)
