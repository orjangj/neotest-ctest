local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)
vim.opt.loadplugins = true

local workspace = os.getenv("GITHUB_WORKSPACE")
if not workspace then
  -- NOTE: Fallback is intended for local development
  local this_file = debug.getinfo(1, "S").source:sub(2) -- remove leading @
  -- Resolve to the repository root (two levels up from tests/unit/)
  workspace = vim.fn.fnamemodify(this_file, ":p:h:h:h")
end

require("lazy").setup({
  "nvim-neotest/neotest",
  commit = "fd0b7986dd0ae04e38ec7dc0c78a432e3820839c", -- see: https://github.com/nvim-neotest/neotest/issues/531 and https://github.com/nvim-neotest/neotest/pull/596
  dependencies = {
    { "nvim-neotest/nvim-nio" },
    { "nvim-lua/plenary.nvim" },
    { "nvim-treesitter/nvim-treesitter", branch = "master" },
    { "orjangj/neotest-ctest" },
  },
  opts = function()
    return { adapters = { require("neotest-ctest") } }
  end,
}, {
  dev = {
    path = vim.fn.fnamemodify(workspace, ":h"),
    patterns = { "neotest-ctest" },
    fallback = true,
  },
})

-- Ensure the cpp treesitter parser is installed synchronously before tests run
pcall(vim.cmd, "TSInstallSync cpp")
