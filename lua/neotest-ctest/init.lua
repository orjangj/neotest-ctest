local logger = require("neotest.logging")
local nio = require("nio")
local lib = require("neotest.lib")
local ctest = require("neotest-ctest.ctest")

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

  --vim.notify(vim.inspect(tree))

  local supported_types = { "test", "namespace", "file" }
  local position = tree:data()
  if not vim.tbl_contains(supported_types, position.type) then
    return
  end

  local root = adapter.root(position.path)
  local test_dir = ctest.find_test_directory(root)
  if not test_dir then
    error("Failed to locate CTest test directory")
  end

  local framework = require("neotest-ctest.framework").detect(position.path)

  -- Collect runnable tests (known to CTest)
  local testcases = ctest.testcases(test_dir)
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

  local results_path = nio.fn.tempname()

  local command = {
    "ctest",
    "--quiet",
    "--output-on-failure",
    "--output-junit",
    results_path,
    filter
  }

  return {
    command = table.concat(command, " "),
    cwd = test_dir,
    context = {
      results_path = results_path,
      framework = framework,
    },
  }
end

function adapter.results(spec, result, tree)
  local results = {}
  local content = lib.files.read(spec.context.results_path)
  local junit = lib.xml.parse(content)
  local testsuite = junit.testsuite
  local testcases = tonumber(testsuite._attr.tests) < 2 and { testsuite.testcase } or testsuite.testcase

  -- Gather all test results in a friendly to use format
  local ctest_results = {}
  for _, testcase in pairs(testcases) do
    ctest_results[testcase._attr.name] = {
      status = testcase._attr.status,
      message = testcase["system-out"],
    }
  end

  local discovered_tests = {}
  for _, node in tree:iter() do
    if node.type == "test" then
      table.insert(discovered_tests, node)
    end
  end

  -- TODO: file/dir/namespace are marked as passed when all tests are skipped
  -- Not sure if this is the intended behavior of Neotest, or if I'm doing something wrong.

  for _, test in pairs(discovered_tests) do
    local candidate = ctest_results[test.name]

    if not candidate then
      -- NOTE: Not known to CTest
      results[test.id] = { status = "skipped" }
    else
      if candidate.status == "run" then
        results[test.id] = { status = "passed" }
      elseif candidate.status == "fail" then
        local short = vim.trim(string.match(candidate.message, "%[%s+RUN%s+%](.-)%[%s+FAILED%s+%]"))
        local linenr, reason = spec.context.framework.parse_error_message(short)

        local output = nio.fn.tempname()
        lib.files.write(output, candidate.message)

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
