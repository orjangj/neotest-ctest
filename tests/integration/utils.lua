local M = {}

local state

M.setup = function()
  if state then
    return state
  end

  local neotest = require("neotest")
  local client

  local opts = {
    log_level = 0,
    adapters = {
      require("neotest-ctest").setup({}),
    },
    consumers = {
      integration_tests = function(_client)
        client = _client
      end,
    },
  }

  neotest.setup(opts)

  client:get_adapters()

  local cwd = vim.loop.cwd()

  local project_root = cwd
  local example_root = project_root .. "/tests/integration/example"
  local adapter_id = "neotest-ctest:" .. project_root

  state = {
    neotest = neotest,
    client = client,
    project_root = project_root,
    example_root = example_root,
    adapter_id = adapter_id,
  }

  return state
end

M.make_neotest_id = function(file_path, args)
  args = args or {}

  local lib = require("neotest.lib")
  local id = lib.files.path.real(file_path)

  ---- Make id compatible with windows (we need the double path separators)
  local sysname = vim.loop.os_uname().sysname
  if sysname ~= "Linux" and sysname ~= "Darwin" then
    -- Assume Windows
    if id ~= nil then
      id = string.gsub(id, "/", [[\]])
    end
  end

  if args.namespace ~= nil then
    id = table.concat({ id, args.namespace }, "::")
  end
  if args.name ~= nil then
    id = table.concat({ id, args.name }, "::")
  end
  return id
end

return M
