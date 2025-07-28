local config = require("neotest-ctest.config")
local lib = require("neotest.lib")
local nio = require("nio")

local M = {}

local function has_matches(query, content, lang)
  nio.scheduler()

  local lang_tree = vim.treesitter.get_string_parser(
    content,
    lang,
    -- Prevent neovim from trying to read the query from injection files
    { injections = { [string.format("%s", lang)] = "" } }
  )

  local root = lib.treesitter.fast_parse(lang_tree):root()
  local normalized_query = lib.treesitter.normalise_query(lang, query)

  for _, match in normalized_query:iter_matches(root, content) do
    if match then
      return true
    end
  end

  return false
end

M.detect = function(file_path)
  for _, name in pairs(config.frameworks) do
    local framework = require("neotest-ctest.framework." .. name)

    local query = framework.include_query
    local language = framework.lang
    local content = lib.files.read(file_path)

    if has_matches(query, content, language) then
      return framework
    end
  end

  return nil
end

return M
