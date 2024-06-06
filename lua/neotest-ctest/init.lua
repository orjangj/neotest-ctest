local logger = require("neotest.logging")
local nio = require("nio")
local lib = require("neotest.lib")

---@type neotest.Adapter
local adapter = { name = "neotest-ctest" }

function adapter.root(dir)
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

  local root = adapter.root(position.path) or vim.loop.cwd()
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

  local discovered_tests = {}
  for _, node in tree:iter() do
    if node.type == "test" then
      table.insert(discovered_tests, node)
    end
  end

  for _, test in pairs(discovered_tests) do
    local testcase = testsuite[test.name]

    if not testcase then
      logger.warn(string.format("Unknown CTest testcase '%s' (marked as skipped)", test.name))
      results[test.id] = { status = "skipped" }
    else
      if testcase.status == "run" then
        results[test.id] = { status = "passed" }
      elseif testcase.status == "fail" then
        local short = testcase.error.message
        local linenr, reason = context.framework.parse_error_message(short)
        local output = nio.fn.tempname()
        lib.files.write(output, testcase.output)

        results[test.id] = {
          status = "failed",
          short = short,
          output = output,
          errors = {
            {
              line = linenr - 1, -- NOTE: Neotest adds 1 for some reason.
              message = reason,
            },
          },
        }
      else
        results[test.id] = { status = "skipped" }
      end
    end
  end

  return results
end

return adapter
