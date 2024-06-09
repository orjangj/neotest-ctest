local gtest = {}

gtest.lang = "cpp"
gtest.query = [[
  ;; query 
  ((namespace_definition
    name: (namespace_identifier) @namespace.name
  )) @namespace.definition
  ;; query
  ((function_definition
    declarator: (function_declarator
      declarator: (identifier) @test.kind (#any-of? @test.kind "TEST" "TEST_F")
      parameters: (parameter_list
        . (parameter_declaration type: (type_identifier) !declarator) @test.suite
        . (parameter_declaration type: (type_identifier) !declarator) @test.name
        .
      )
    )
  )) @test.definition
]]

function gtest.parse_errors(output)
  local capture = vim.trim(string.match(output, "%[%s+RUN%s+%](.-)%[%s+FAILED%s+%]"))

  local errors = {}

  for failures in string.gmatch(capture .. "\n\n", "(.-)[\r\n][\r\n]") do
    local t = {}
    for str in string.gmatch(failures .. "Failure", "(.-)Failure") do
      table.insert(t, vim.trim(str))
    end

    local linenr = tonumber(vim.split(t[1], ":")[2])
    local reason = t[2]

    table.insert(errors, { line = linenr, message = reason })
  end

  return errors
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
      local suite = vim.treesitter.get_node_text(captured_nodes["test.suite"], source)
      name = suite .. "." .. name
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
