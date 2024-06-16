local assert = require("luassert")
local adapter = require("neotest-ctest")
local Tree = require("neotest.types").Tree
local it = require("nio").tests.it

adapter.setup({})

-- TODO: remove the summary stuff

describe("position.type == test", function()
  local spec, test_file, positions, tree

  before_each(function()
    test_file = "TEST_test.cpp"
    positions = {
      {
        id = ("%s::%s"):format(test_file, "Suite.First"),
        name = "Suite.First",
        path = test_file,
        range = { 4, 0, 4, 41 },
        type = "test",
      },
    }
    tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    spec = {
      context = {
        ctest = {
          parse_test_results = function()
            return {}
          end,
        },
        framework = {
          parse_errors = function(_)
            return {}
          end,
        },
      },
    }
  end)

  it("adapter.results should set status as 'passed' given a passing test", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "run",
          time = 0,
          output = "",
        },
        summary = {
          tests = 1,
          failures = 0,
          skipped = 0,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("passed", results[test_file .. "::Suite.First"].status)
  end)

  it("adapter.results should set status as 'failed' given a failing test", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "fail",
          time = 0,
          output = "",
        },
        summary = {
          tests = 1,
          failures = 1,
          skipped = 0,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("failed", results[test_file .. "::Suite.First"].status)
  end)

  it("adapter.results should set status as 'skipped' given a skipped test", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "skipped",
          output = "",
        },
        summary = {
          tests = 1,
          failures = 0,
          skipped = 1,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("skipped", results[test_file .. "::Suite.First"].status)
  end)

  it("adapter.results should set status as 'skipped' given an unknown test", function()
    -- NOTE: Unknown as in "not known to CTest" (i.e. not compiled yet)
    spec.context.ctest.parse_test_results = function()
      return {}
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("skipped", results[test_file .. "::Suite.First"].status)
  end)
end)

describe("position.type == namespace", function()
  local spec, test_file, namespace, positions, tree

  before_each(function()
    test_file = "TEST_test.cpp"
    namespace = "namespace"
    positions = {
      {
        id = test_file .. "::" .. namespace,
        name = namespace,
        path = test_file,
        range = { 2, 0, 7, 1 },
        type = "namespace",
      },
      {
        {
          id = test_file .. "::" .. namespace .. "::" .. "Suite.First",
          name = "Suite.First",
          path = test_file,
          range = { 4, 0, 4, 41 },
          type = "test",
        },
      },
      {
        {
          id = test_file .. "::" .. namespace .. "::" .. "Suite.Second",
          name = "Suite.Second",
          path = test_file,
          range = { 5, 0, 5, 41 },
          type = "test",
        },
      },
    }
    tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    spec = {
      context = {
        ctest = {
          parse_test_results = function()
            return {}
          end,
        },
        framework = {
          parse_errors = function(_)
            return {}
          end,
        },
      },
    }
  end)

  it("adapter.results should set status as 'passed' given passing tests", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "run",
          time = 0,
          output = "",
        },
        ["Suite.Second"] = {
          status = "run",
          time = 0,
          output = "",
        },
        summary = {
          tests = 2,
          failures = 0,
          skipped = 0,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("passed", results[test_file .. "::" .. namespace].status)
  end)

  it("adapter.results should set status as 'failed' for one or more failing tests", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "run",
          time = 0,
          output = "",
        },
        ["Suite.Second"] = {
          status = "fail",
          time = 0,
          output = "",
        },
        summary = {
          tests = 2,
          failures = 1,
          skipped = 0,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("failed", results[test_file .. "::" .. namespace].status)
  end)

  it("adapter.results should set status as 'skipped' when all tests are skipped", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "skipped",
          time = 0,
          output = "",
        },
        ["Suite.Second"] = {
          status = "skipped",
          time = 0,
          output = "",
        },
        summary = {
          tests = 2,
          failures = 0,
          skipped = 2,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("skipped", results[test_file .. "::" .. namespace].status)
  end)
end)

describe("position.type == file", function()
  local spec, test_file, positions, tree, namespace

  before_each(function()
    test_file = "TEST_test.cpp"
    namespace = "namespace"
    positions = {
      {
        id = test_file,
        name = test_file,
        path = test_file,
        range = { 0, 0, 24, 0 },
        type = "file",
      },
      {
        {
          id = test_file .. "::" .. namespace,
          name = namespace,
          path = test_file,
          range = { 2, 0, 6, 1 },
          type = "namespace",
        },
        {
          {
            id = test_file .. "::" .. namespace .. "::" .. "Suite.First",
            name = "Suite.First",
            path = test_file,
            range = { 4, 0, 4, 41 },
            type = "test",
          },
        },
      },
      {
        {
          id = test_file .. "::" .. "Suite.Second",
          name = "Suite.Second",
          path = test_file,
          range = { 8, 0, 11, 1 },
          type = "test",
        },
      },
    }
    tree = Tree.from_list(positions, function(pos)
      return pos.id
    end)
    spec = {
      context = {
        ctest = {
          parse_test_results = function()
            return {}
          end,
        },
        framework = {
          parse_errors = function(_)
            return {}
          end,
        },
      },
    }
  end)

  it("adapter.results should set status as 'passed' given passing tests", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "run",
          time = 0,
          output = "",
        },
        ["Suite.Second"] = {
          status = "run",
          time = 0,
          output = "",
        },
        summary = {
          tests = 2,
          failures = 0,
          skipped = 0,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("passed", results[test_file].status)
  end)

  it("adapter.results should set status as 'failed' for one or more failing tests", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "fail",
          time = 0,
          output = "",
        },
        ["Suite.Second"] = {
          status = "run",
          time = 0,
          output = "",
        },
        summary = {
          tests = 2,
          failures = 1,
          skipped = 0,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("failed", results[test_file].status)
  end)

  it("adapter.results should set status as 'skipped' when all tests are skipped", function()
    spec.context.ctest.parse_test_results = function()
      return {
        ["Suite.First"] = {
          status = "skipped",
          time = 0,
          output = "",
        },
        ["Suite.Second"] = {
          status = "skipped",
          time = 0,
          output = "",
        },
        summary = {
          tests = 2,
          failures = 0,
          skipped = 2,
          time = 0,
          output = "",
        },
      }
    end
    local results = adapter.results(spec, nil, tree)
    assert.equals("skipped", results[test_file].status)
  end)

  describe("contains a namespace with passing tests and a failing non-namespaced test", function()
    it("adapter.results should set namespace status as passed and file status as failed", function()
      spec.context.ctest.parse_test_results = function()
        return {
          ["Suite.First"] = {
            status = "run",
            time = 0,
            output = "",
          },
          ["Suite.Second"] = {
            status = "fail",
            time = 0,
            output = "",
          },
          summary = {
            tests = 2,
            failures = 1,
            skipped = 0,
            time = 0,
            output = "",
          },
        }
      end
      local results = adapter.results(spec, nil, tree)
      assert.equals("failed", results[test_file].status)
      assert.equals("passed", results[test_file .. "::" .. namespace].status)
    end)
  end)
end)
