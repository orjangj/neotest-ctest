local M = {}

M.name = "GoogleTest"
M.lang = "cpp"
M.query = [[
    ((function_definition
    	declarator: (
          function_declarator
            declarator: (identifier) @test.kind
          parameters: (
            parameter_list
              . (parameter_declaration type: (type_identifier) !declarator) @namespace.name
              . (parameter_declaration type: (type_identifier) !declarator) @test.name
              .
          )
        )
        !type
    )
    (#any-of? @test.kind "TEST" "TEST_F" "TEST_P"))
    @test.definition
  ]]

function M.parse_error_message(output)
  local t = {}

  for str in string.gmatch(output, "[^\r\n$]+") do
    table.insert(t, vim.trim(str))
  end

  local linenr = tonumber(vim.split(t[2], ":")[2])
  local reason = table.concat(vim.list_slice(t, 3), ", ")

  return linenr, reason
end

return M
