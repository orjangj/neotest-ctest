local logger = require("neotest.logging")
local nio = require("nio")
local lib = require("neotest.lib")

---@type neotest.Adapter
local adapter = { name = "neotest-ctest" }

function adapter.root(dir)
  -- TODO: Need to come up with better rules for reporting root. CMakeLists.txt
  -- are usually contained in multiple sub-directories, and this can be problematic
  -- if dir input is anything else than the project root.
  return lib.files.match_root_pattern("CMakeLists.txt")(dir)
end

function adapter.filter_dir(name, _, _)
  local dir_filters = {
    ["build"] = false,
    ["out"] = false,
    ["venv"] = false,
  }

  return dir_filters[name] == nil
end

function adapter.is_test_file(file_path)
  local elems = vim.split(file_path, lib.files.sep, { plain = true })
  local name, extension = unpack(vim.split(elems[#elems], ".", { plain = true }))

  local supported_extensions = { "cpp", "cc", "cxx" }

  return vim.tbl_contains(supported_extensions, extension) and vim.endswith(name, "_test") or false
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

  -- XXX: Not sure if using cwd is the best approach, but most people are probably going to
  -- open Neovim at project root.
  local cwd = vim.loop.cwd()
  local ctest = require("neotest-ctest.ctest"):new(cwd)

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

  local command = ctest:command({ filter })
  local framework = require("neotest-ctest.framework").detect(position.path)

  return {
    command = command,
    context = {
      ctest = ctest,
      framework = framework,
    },
  }
end

function adapter.results(spec, _, tree)
  local results = {}
  local context = spec.context

  local testsuite = context.ctest:parse_test_results()

  for _, node in tree:iter() do
    if node.type == "file" or node.type == "namespace" then
      local summary = testsuite.summary
      local status

      if summary.failures > 0 then
        status = "failed"
      elseif summary.skipped == summary.tests then
        status = "skipped"
      else
        status = "passed"
      end

      local short = {
        "---------- CTest Summary ----------",
        ("Total test time: %.6f seconds"):format(summary.time),
        ("Test cases: %d"):format(summary.tests),
        ("    Passed: %d"):format(summary.tests - summary.failures - summary.skipped),
        ("    Failed: %d"):format(summary.failures),
        ("   Skipped: %d"):format(summary.skipped),
        "-----------------------------------",
      }

      results[node.id] = {
        status = status,
        short = table.concat(short, "\n"),
        output = summary.output,
      }
    elseif node.type == "namespace" then
      results[node.id] = { output = testsuite.summary.output }
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
            output = testsuite.summary.output
          }
        elseif testcase.status == "fail" then
          local errors = context.framework.parse_errors(testcase.output)

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
    else
      logger.error(("Unknown node type '%s'"):format(node.type))
    end
  end

  return results
end

return adapter
