local lib = require("neotest.lib")
local nio = require("nio")

local M = {}

M.supported_frameworks = {
  gtest = require("neotest-ctest.framework.gtest"),
}

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
  -- TODO: throttle?
  local content = lib.files.read(file_path)

  for name, framework in pairs(M.supported_frameworks) do
    local query = ([[
      ;; query
      (preproc_include
        path: (system_lib_string) @system.include
        (#match? @system.include "^\\<%s/.*\\>$")
      )
    ]]):format(name)

    if has_matches(query, content, framework.lang) then
      return framework
    end
  end

  return nil
end

return M
