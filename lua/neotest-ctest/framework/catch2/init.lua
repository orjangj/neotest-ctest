local catch2 = {}

catch2.lang = "cpp"
catch2.query = [[
  ((namespace_definition
    name: (namespace_identifier) @namespace.name)
    @namespace.definition
  )

  (expression_statement
    (call_expression
      function: (identifier) @test.kind
      arguments: (argument_list
        . (string_literal (string_content)) @test.name
        . (string_literal (string_content)) @test.group
        .
      )
    )
    !type
    (#eq? @test.kind "TEST_CASE")
  ) @test.definition
]]

function catch2.parse_errors(output)
  local capture = vim.trim(string.match(output, "%.%.%.+[\r\n](.-)%=%=%=+"))

  local errors = {}

  for failures in string.gmatch(capture .. "\n\n", "(.-)[\r\n][\r\n]") do
    local t = {}
    for str in string.gmatch(failures .. "FAILED:", "(.-)FAILED:") do
      table.insert(t, vim.trim(str))
    end

    local linenr = tonumber(vim.split(t[1], ":")[2])
    local reason = t[2] --string.gsub(t[2], "[\r\n%s]+", " ")  -- TODO: strip if using virtual text?

    table.insert(errors, { line = linenr, message = reason })
  end

  return errors
end

function catch2.build_position(file_path, source, captured_nodes)
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

    local position = {
      type = match_type,
      path = file_path,
      name = string.gsub(name, '"', ""),
      range = { definition:range() },
    }

    return position
  end
end

function catch2.parse_positions(path)
  local lib = require("neotest.lib")
  local opts = { build_position = "require('neotest-ctest.framework.catch2').build_position" }
  return lib.treesitter.parse_positions(path, catch2.query, opts)
end

return catch2
