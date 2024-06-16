local config = require("neotest-ctest.config")
local logger = require("neotest.logging")

---@type neotest.Adapter
local adapter = { name = "neotest-ctest" }

adapter.setup = function(user_config)
  config.setup(user_config)
  return adapter
end

function adapter.root(dir)
  return config.root(dir)
end

function adapter.filter_dir(name, rel_path, root)
  return config.filter_dir(name, rel_path, root)
end

function adapter.is_test_file(file_path)
  return config.is_test_file(file_path)
end

function adapter.discover_positions(path)
  local framework = require("neotest-ctest.framework").detect(path)
  if not framework then
    logger.error("Failed to detect test framework for file: " .. path)
    return
  end

  return framework.parse_positions(path)
end

---@param args neotest.RunArgs
function adapter.build_spec(args)
  local tree = args and args.tree
  if not tree then
    return
  end

  local supported_types = { "test", "namespace", "file" }
  local position = tree:data()
  if not vim.tbl_contains(supported_types, position.type) then
    return
  end

  local cwd = vim.loop.cwd()
  local root = adapter.root(cwd) or cwd
  local ctest = require("neotest-ctest.ctest"):new(root)

  -- Collect runnable tests (known to CTest)
  local testcases = ctest:testcases()
  local runnable_tests = {}
  for _, node in tree:iter() do
    if node.type == "test" then
      -- NOTE: If the node.name is not known by CTest (testcases[node.name] == nil), then
      -- it will be marked as 'skipped' when parsing test results.
      table.insert(runnable_tests, testcases[node.name])
    end
  end

  -- NOTE: The '-I Start,End,Stride,test#,test#,...' option runs the specified tests in the
  -- range starting from number Start, ending at number End, incremented by number Stride.
  -- If Start, End and Stride are set to 0, then CTest will run all test# as specified.
  local filter = string.format("-I 0,0,0,%s", table.concat(runnable_tests, ","))

  local extra_args = config.extra_args or {}
  vim.list_extend(extra_args, args.extra_args or {})
  local ctest_args = { filter, table.concat(extra_args, " ") }

  local command = ctest:command(ctest_args)
  local framework = require("neotest-ctest.framework").detect(position.path)

  return {
    command = command,
    context = {
      ctest = ctest,
      framework = framework,
    },
  }
end

local function prepare_results(tree, testsuite, framework)
  local node = tree:data()
  local results = {}

  if node.type == "file" or node.type == "namespace" then
    local passed = 0
    local failed = 0
    for _, child in pairs(tree:children()) do
      local r = prepare_results(child, testsuite, framework)
      for n, v in pairs(r) do
        results[n] = v
        if v.status == "passed" then
          passed = passed + 1
        elseif v.status == "failed" then
          failed = failed + 1
        end
      end
    end

    local status = failed > 0 and "failed" or passed > 0 and "passed" or "skipped"
    results[node.id] = { status = status, output = testsuite.summary.output }
  elseif node.type == "test" then
    local testcase = testsuite[node.name]

    if not testcase then
      logger.warn(string.format("Unknown CTest testcase '%s' (marked as skipped)", node.name))
      results[node.id] = { status = "skipped" }
    else
      if testcase.status == "run" then
        results[node.id] = {
          status = "passed",
          short = ("Passed in %.6f seconds"):format(testcase.time),
          output = testsuite.summary.output,
        }
      elseif testcase.status == "fail" then
        local errors = framework.parse_errors(testcase.output)

        -- NOTE: Neotest adds 1 for some reason.
        for _, error in pairs(errors) do
          error.line = error.line - 1
        end

        results[node.id] = {
          status = "failed",
          short = testcase.output,
          output = testsuite.summary.output,
          errors = errors,
        }
      else
        results[node.id] = { status = "skipped" }
      end
    end
  end

  return results
end

function adapter.results(spec, _, tree)
  local context = spec.context
  local testsuite = context.ctest:parse_test_results()
  return prepare_results(tree, testsuite, context.framework)
end

return adapter
