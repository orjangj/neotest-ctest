local lib = require("neotest.lib")
local nio = require("nio")

local ctest = {}

local function run(test_dir, args)
  local runner = nio.process.run({
    cmd = "ctest",
    cwd = test_dir,
    args = args,
  })

  if not runner then
    return
  end

  local output = runner.stdout.read()
  runner.close()

  return output
end

function ctest:new(cwd)
  local ctest_roots = require("plenary.scandir").scan_dir(cwd, {
    respect_gitignore = false,
    depth = 3, -- NOTE: support multi-config projects
    search_pattern = "CTestTestfile.cmake",
    silent = true,
  })

  local test_dir = next(ctest_roots) and lib.files.parent(ctest_roots[1]) or nil

  if not test_dir then
    error("Failed to locate CTest test directory")
  end

  local version = run(test_dir, { "--version" })

  if not version then
    error("Failed to determine CTest version")
  end

  local major, minor, _ = string.match(version, "(%d+)%.(%d+)%.(%d+)")
  if not (tonumber(major) >= 3 and tonumber(minor) >= 21) then
    error("CTest version 3.21+ is required!")
  end

  local output_junit_path = nio.fn.tempname()
  local output_log_path = nio.fn.tempname()

  local session = {
    _test_dir = test_dir,
    _output_junit_path = output_junit_path,
    _output_log_path = output_log_path,
  }
  setmetatable(session, self)
  self.__index = self
  return session
end

function ctest:command(args)
  args = args or {}
  local command = {
    "ctest",
    "--test-dir",
    self._test_dir,
    "--quiet",
    "--output-on-failure",
    "--output-junit",
    self._output_junit_path,
    "--output-log",
    self._output_log_path,
    table.concat(args, " "),
  }

  return table.concat(command, " ")
end

function ctest:testcases()
  local testcases = {}

  local output = run(self._test_dir, { "--show-only=json-v1" })

  if output then
    output = string.gsub(output, "[\n\r]", "")
    local decoded = vim.json.decode(output)

    for index, test in ipairs(decoded.tests) do
      testcases[test.name] = index
    end
  else
    -- TODO: log error?
  end

  return testcases
end

function ctest:parse_test_results()
  local junit_data = lib.files.read(self._output_junit_path)
  local junit = lib.xml.parse(junit_data)
  local testsuite = junit.testsuite
  local testcases = tonumber(testsuite._attr.tests) < 2 and { testsuite.testcase } or testsuite.testcase

  local results = {}

  -- NOTE: CTest doesn't seem to populate the testsuite._attr.time, so we'll have to
  -- compute it ourselves.
  local total_time = 0

  for _, testcase in pairs(testcases) do
    local name = testcase._attr.name
    local status = testcase._attr.status
    local time = tonumber(testcase._attr.time)
    total_time = total_time + time

    -- XXX: CTest only populates the "system-out"
    -- See: https://gitlab.kitware.com/cmake/cmake/-/issues/22478
    local output = testcase["system-out"]

    results[name] = {
      status = status,
      time = time,
      output = output,
    }
  end

  results.summary = {
    tests = tonumber(testsuite._attr.tests),
    failures = tonumber(testsuite._attr.failures),
    skipped = tonumber(testsuite._attr.skipped),
    time = total_time,
    output = self._output_log_path
  }

  return results
end

return ctest
