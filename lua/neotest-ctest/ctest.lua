local logger = require("neotest.logging")

local M = {}

M.run = function(test_dir, opts, callback)
  local command = "ctest " .. opts

  local jobid = vim.fn.jobstart(command, {
    cwd = test_dir,
    stdout_buffered = true,
    -- TODO: on_stderr doesn't seem to be reliable. Not sure why...
    -- Checking if stdout was called as expected instead after calling jobwait
    on_stdout = callback,
  })

  if jobid == 0 or jobid == -1 then
    logger.error(("neotest-ctest: failed to run `%s`"):format(command))
    return
  end

  local timeout = 100
  if vim.fn.jobwait({ jobid }, timeout) == -1 then
    logger.error(("neotest-ctest: `%s` did not complete within %s ms"):format(command, timeout))
  end
end

M.testcases = function(test_dir)
  local testcases = {}

  M.run(test_dir, "--show-only=json-v1", function(_, data)
    if not data then
      return
    end

    local json = ""
    for _, line in pairs(data) do
      json = json .. line
    end

    local decoded = vim.json.decode(json)

    for index, test in ipairs(decoded.tests) do
      testcases[test.name] = index -- TODO: Why was it implemented like this?
    end
  end)

  return testcases
end

return M
