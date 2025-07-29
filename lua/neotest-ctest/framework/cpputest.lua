local cpputest = {}

cpputest.lang = "cpp"
cpputest.include_query = [[
  ;; query
  (preproc_include
    path: (system_lib_string) @system.include
    (#match? @system.include "^\\<CppUTest/.*\\>$")
  )
  ;; query
  (preproc_include
    path: (string_literal) @local.include
    (#match? @local.include "^\"CppUTest/.*\"$")
  )
]]
cpputest.tests_query = [[
  ;; query
  ((namespace_definition
    name: (namespace_identifier) @namespace.name
  )) @namespace.definition
  ;; query
  ((function_definition
    declarator: (function_declarator
      declarator: (identifier) @test.kind (#any-of? @test.kind "TEST")
      parameters: (parameter_list
        . (parameter_declaration type: (type_identifier) !declarator) @test.group
        . (parameter_declaration type: (type_identifier) !declarator) @test.name
        .
      )
    )
  )) @test.definition
]]

function cpputest.parse_errors(output)
  local errors = {}

  local t = {}
  for str in string.gmatch(output, "[^\r\n$]+") do
    table.insert(t, str)
  end

  -- Narrow down the information we need
  t = vim.list_slice(t, 2, #t - 2)

  local linenr = tonumber(vim.split(t[1], ":")[2])
  local reason = table.concat(vim.list_slice(t, 2), "\n")
  table.insert(errors, { line = linenr, message = reason })

  return errors
end

function cpputest.build_position(file_path, source, captured_nodes)
  local match_type
  if captured_nodes["test.name"] then
    match_type = "test"
  end
  if captured_nodes["namespace.name"] then
    match_type = "namespace"
  end

  if match_type then
    ---@type string
    local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)
    local definition = captured_nodes[match_type .. ".definition"]

    if match_type == "test" then
      local group = vim.treesitter.get_node_text(captured_nodes["test.group"], source)
      name = group .. "." .. name
    end

    local position = {
      type = match_type,
      path = file_path,
      name = name,
      range = { definition:range() },
    }

    return position
  end
end

function cpputest.parse_positions(path)
  local lib = require("neotest.lib")
  local opts = { build_position = "require('neotest-ctest.framework.cpputest').build_position" }
  return lib.treesitter.parse_positions(path, cpputest.tests_query, opts)
end

return cpputest
