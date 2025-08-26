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
  workspace = vim.fn.fnamemodify(this_file, ":h")
end

require("lazy").setup({
  "nvim-neotest/neotest",
  commit = "52fca6717ef972113ddd6ca223e30ad0abb2800c", -- see: https://github.com/nvim-neotest/neotest/issues/531
  dependencies = {
    { "nvim-neotest/nvim-nio" },
    { "nvim-lua/plenary.nvim" },
    { "nvim-treesitter/nvim-treesitter" },
    { "orjangj/neotest-ctest" },
  },
  opts = function()
    local ts_config = require("nvim-treesitter.configs")
    ts_config.setup({ ensure_installed = { "c", "cpp", "lua" } })
    return { adapters = { require("neotest-ctest") } }
  end,
}, {
  dev = {
    path = vim.fn.fnamemodify(workspace, ":h"),
    patterns = { "neotest-ctest" },
    fallback = true,
  },
})
