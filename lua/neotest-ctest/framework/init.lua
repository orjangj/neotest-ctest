local lib = require("neotest.lib")
local nio = require("nio")

local M = {}

M.supported_frameworks = {
  gtest = require("neotest-ctest.framework.gtest"),
}

local function make_include_query(name)
  local filters = {}

  local system_lib_string_query = ([[
    ;; query
    (preproc_include
      path: (system_lib_string) @system.include
      (#any-of? @system.include "<%s.h>" "<%s/%s.h>")
    )
  ]]):format(name, name, name)

  local string_literal_query = ([[
    ;; query
    (preproc_include
      path: (string_literal (string_content)) @string.include
      (#any-of? @string.include "\"%s.h\"" "\"%s/%s.h\"")
    )
  ]]):format(name, name, name)

  table.insert(filters, system_lib_string_query)
  table.insert(filters, string_literal_query)

  return table.concat(filters, "\n")
end

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
  -- TODO: Use frameworks = config.frameworks or M.supported_frameworks
  -- to allow users to select range and order of priority

  local content = lib.files.read(file_path)

  for name, framework in pairs(M.supported_frameworks) do
    local query = make_include_query(name)
    if has_matches(query, content, framework.lang) then
      return framework
    end
  end

  return nil
end

return M
