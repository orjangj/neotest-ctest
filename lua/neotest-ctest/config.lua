local lib = require("neotest.lib")

local M = {}

local function default_is_test_file(file_path)
  local elems = vim.split(file_path, lib.files.sep, { plain = true })
  local name, extension = unpack(vim.split(elems[#elems], ".", { plain = true }))
  local supported_extensions = { "cpp", "cc", "cxx" }
  return vim.tbl_contains(supported_extensions, extension) and vim.endswith(name, "_test") or false
end

local function default_root(dir)
  -- NOTE: CMakeLists.txt is not a good candidate as it can be found in more than one directory
  return lib.files.match_root_pattern(
    "CMakePresets.json",
    "compile_commands.json",
    ".clangd",
    ".clang-format",
    ".clang-tidy",
    "build",
    "out",
    ".git"
  )(dir)
end

local function default_filter_dir(name, rel_path, root)
  local neotest_config = require("neotest.config")
  local fn = vim.tbl_get(neotest_config, "projects", root, "discovery", "filter_dir")
  if fn ~= nil then
    return fn(name, rel_path, root)
  end

  local dir_filters = {
    ["build"] = false,
    ["cmake"] = false,
    ["doc"] = false,
    ["docs"] = false,
    ["examples"] = false,
    ["out"] = false,
    ["scripts"] = false,
    ["tools"] = false,
    ["venv"] = false,
  }
  return dir_filters[name] == nil
end

local default_config = {
  root = default_root,
  is_test_file = default_is_test_file,
  filter_dir = default_filter_dir,
  frameworks = { "gtest", "catch2", "doctest", "cpputest" },
  cmd = { "ctest" },
  extra_args = {},
}

local config = default_config

local module_metatable = {
  __index = function(_, key)
    return config[key]
  end,
  __newindex = function(_, key, value)
    if key == "setup" then
      rawset(M, key, value)
    end
    config[key] = value
  end,
}

setmetatable(M, module_metatable)

function M.setup(user_config)
  user_config = user_config or {}
  config = vim.tbl_deep_extend("force", default_config, user_config)
end

-- for tests
function M.get()
  return config
end

function M.get_default()
  return default_config
end

return M
