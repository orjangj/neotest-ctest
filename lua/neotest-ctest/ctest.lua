local lib = require("neotest.lib")
local scandir = require("plenary.scandir")
local nio = require("nio")

local M = {}

M.run = function(test_dir, args)
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

M.testcases = function(test_dir)
  local testcases = {}

  local output = M.run(test_dir, { "--show-only=json-v1" })

  if output then
    output = string.gsub(output, "[\n\r]", "")
    local decoded = vim.json.decode(output)

    for index, test in ipairs(decoded.tests) do
      testcases[test.name] = index -- TODO: Why was it implemented like this?
    end
  else
    -- TODO: log error?
  end

  return testcases
end

-- TODO: Document
-- Use the first configuration found, or nil if not found
M.find_test_directory = function(cwd)
  local ctest_roots = scandir.scan_dir(cwd, {
    respect_gitignore = false,
    depth = 3, -- NOTE: support multi-config projects
    search_pattern = "CTestTestfile.cmake",
    silent = true,
  })

  return next(ctest_roots) and lib.files.parent(ctest_roots[1]) or nil
end

return M
