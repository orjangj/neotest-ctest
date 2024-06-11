local catch2 = {}

catch2.lang = "cpp"
catch2.query = [[
  ;; query
  ((namespace_definition
    name: (namespace_identifier) @namespace.name
  )) @namespace.definition
  ;; query
  ;; NOTE: There seem to be some limitation with either treesitter or the cpp treesitter parser
  ;; to capture range of sibling nodes. See catch2.build_position for workaround using
  ;; @test.statement and @test.body to construct @test.definition
  (
    (expression_statement
      (call_expression
        function: (identifier) @test.kind (#any-of? @test.kind "TEST_CASE" "TEST_CASE_METHOD" "SCENARIO")
        arguments: (argument_list
          . (identifier) ? @test.fixture
          . (string_literal (string_content) @test.name )
          . (string_literal (string_content) @test.tag ) ?
          .
        )
      )
    ) @test.statement
    . (compound_statement) @test.body
  )
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
    local reason = t[2]
    local error = { line = linenr, message = reason }

    -- parse_errors is imperfect if GENERATE() macro has been used in the catch test
    if not vim.tbl_isempty(error) then
      table.insert(errors, error)
    end
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
    local kind = vim.treesitter.get_node_text(captured_nodes[match_type .. ".kind"], source)
    ---@type string
    local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)

    if kind == "SCENARIO" then
      name = "Scenario: " .. name
    end

    -- NOTE: Construct test definition from captured sibling nodes
    local statement = { captured_nodes[match_type .. ".statement"]:range() }
    local body = { captured_nodes[match_type .. ".body"]:range() }
    local definition = { statement[1], statement[2], body[3], body[4] }

    local position = {
      type = match_type,
      path = file_path,
      name = name,
      range = definition,
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
