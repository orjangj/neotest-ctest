local gtest = {}

gtest.name = "GoogleTest"
gtest.lang = "cpp"
gtest.query = [[
  ((namespace_definition
    name: (namespace_identifier) @namespace.name)
    @namespace.definition
  )
  (function_definition
    declarator: (function_declarator
      declarator: (identifier) @test.kind
      parameters: (parameter_list
        . (parameter_declaration type: (type_identifier) !declarator) @test.group
        . (parameter_declaration type: (type_identifier) !declarator) @test.name
        .
      )
    )
    !type
    (#any-of? @test.kind "TEST" "TEST_F" "TEST_P")
  ) @test.definition
]]

function gtest.parse_error_message(output)
  local t = {}

  for str in string.gmatch(output, "[^\r\n$]+") do
    table.insert(t, vim.trim(str))
  end

  local linenr = tonumber(vim.split(t[2], ":")[2])
  local reason = table.concat(vim.list_slice(t, 3), " | ")

  return linenr, reason
end

function gtest.build_position(file_path, source, captured_nodes)

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

function gtest.parse_positions(path)
  local lib = require("neotest.lib")
  local opts = { build_position = "require('neotest-ctest.framework.gtest').build_position" }
  return lib.treesitter.parse_positions(path, gtest.query, opts)
end

return gtest
