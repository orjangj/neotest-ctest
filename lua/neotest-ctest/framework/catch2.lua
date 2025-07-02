local logger = require("neotest.logging")
local catch2 = {}

catch2.lang = "cpp"
catch2.query = [[
  ;; query
  ((namespace_definition
    name: (namespace_identifier) @namespace.name
  )) @namespace.definition
  ;; query (tests within namespace)
  ;; NOTE: There seem to be some limitation with either treesitter or the cpp treesitter parser
  ;; to capture range of sibling nodes. See catch2.build_position for workaround using
  ;; @test.statement and @test.body to construct @test.definition
  ((namespace_definition
    name: (namespace_identifier)

    body: (declaration_list
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
      . (compound_statement) @test.body)
  ))
  ;; query (tests without namespace)
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
  local capture = string.match(output, "%.%.%.+[\r\n](.-)%=%=%=+")

  if not capture then
    logger.error("Failed to capture catch2 errors")
    return {}
  end

  local errors = {}

  for failures in string.gmatch(capture .. "\n\n", "(.-)\n\n") do
    print("failures" .. failures)
    for line, message in string.gmatch(failures, ".-[:%(](%d+)%)-:%sFAILED:[\r\n]+(.+)") do
      table.insert(errors, { line = tonumber(line), message = message })
    end
  end

  return errors
end

function catch2.build_position(file_path, source, captured_nodes)
  local position = nil

  if captured_nodes["namespace.name"] then
    position = {
      type = "namespace",
      path = file_path,
      name = vim.treesitter.get_node_text(captured_nodes["namespace.name"], source),
      range = { captured_nodes["namespace.definition"]:range() },
    }
  elseif captured_nodes["test.name"] then
    local name = vim.treesitter.get_node_text(captured_nodes["test.name"], source)
    local kind = vim.treesitter.get_node_text(captured_nodes["test.kind"], source)

    if kind == "SCENARIO" then
      name = "Scenario: " .. name
    end

    -- NOTE: Construct test definition from captured sibling nodes
    local statement = { captured_nodes["test.statement"]:range() }
    local body = { captured_nodes["test.body"]:range() }
    local definition = { statement[1], statement[2], body[3], body[4] }

    position = {
      type = "test",
      path = file_path,
      name = name,
      range = definition,
    }
  end

  return position
end

function catch2.parse_positions(path)
  local lib = require("neotest.lib")
  local opts = { build_position = "require('neotest-ctest.framework.catch2').build_position" }
  return lib.treesitter.parse_positions(path, catch2.query, opts)
end

return catch2
