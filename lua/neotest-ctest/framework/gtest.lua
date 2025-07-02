local logger = require("neotest.logging")
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
  ;; query
  ((function_definition
    declarator: (function_declarator
      declarator: (identifier) @namespace.name (#any-of? @namespace.name "TEST_P")
      parameters: (parameter_list
        . (parameter_declaration type: (type_identifier) !declarator) @namespace.suite
        . (parameter_declaration type: (type_identifier) !declarator) @namespace.test
        .
      )
    )
  )) @namespace.definition
]]

function gtest.parse_errors(output)
  local capture = vim.trim(string.match(output, "%[%s+RUN%s+%].-[\r\n](.-)%[%s+FAILED%s+%]"))

  if not capture then
    logger.error("Failed to capture gtest errors")
    return {}
  end

  -- NOTE: This is a very hacky solution to transform gtest <v1.14.0 to a v.14.0+ formatted error message output
  local tmp = ""
  for str in string.gmatch(capture, "[^\r\n$]+") do
    local line = string.match(str, ".-:(%d+):%sFailure")
    if line then
      tmp = tmp .. "\n\n" .. str
    else
      tmp = tmp .. "\n" .. str
    end
  end

  capture = vim.trim(tmp)

  -- NOTE: At this point, the capture should be compatible with gtest v1.14.0+ (which is considerably easier to parse)
  local errors = {}
  local matches = {
    ".-:(%d+):%sFailure[\r\n](.+)", -- Unix matcher
    ".-%((%d+)%):%serror:(.+)",     -- Windows matcher
  }

  for failures in string.gmatch(capture .. "\n\n", "(.-)\n\n") do
    for _, match in ipairs(matches) do
      for line, message in string.gmatch(failures, match) do
        table.insert(errors, { line = tonumber(line), message = message })
      end
    end
  end

  return errors
end

function gtest.build_parameterized(source, parent)
  local query = ([[
    ;; query
    ((expression_statement
      (call_expression
        function: (identifier) @parameterized.kind (#any-of? @parameterized.kind "INSTANTIATE_TEST_SUITE_P")
        arguments: (argument_list
          . (identifier) @parameterized.group
          . (identifier) @parameterized.suite (#eq? @parameterized.suite "%s")
          . (call_expression
              function: (qualified_identifier
                name: (identifier) @parameterized.param_generator)
              arguments: (argument_list) @parameterized.param_args
            )
        )
      )
    )) @parameterized.definition
  ]]):format(parent.suite)

  local nio = require("nio")
  local lib = require("neotest.lib")

  nio.scheduler()

  local lang_tree = vim.treesitter.get_string_parser(
    source,
    gtest.lang,
    -- Prevent neovim from trying to read the query from injection files
    { injections = { [string.format("%s", gtest.lang)] = "" } }
  )

  local root = lib.treesitter.fast_parse(lang_tree):root()
  local normalized_query = lib.treesitter.normalise_query(gtest.lang, query)

  local positions = {}

  for _, match in normalized_query:iter_matches(root, source) do
    local captured_nodes = {}
    for i, capture in ipairs(normalized_query.captures) do
      captured_nodes[capture] = match[i]
    end

    local group = vim.treesitter.get_node_text(captured_nodes["parameterized.group"], source)
    local param_generator =
      vim.treesitter.get_node_text(captured_nodes["parameterized.param_generator"], source)
    local param_args =
      vim.treesitter.get_node_text(captured_nodes["parameterized.param_args"], source)

    -- TODO: support name_generator
    local prefix = group

    if param_generator == "Range" then
      local p_range = vim.split(string.match(param_args, "%((.-)%)"), ",")
      local p_begin = tonumber(p_range[1])
      local p_end = tonumber(p_range[2]) - 1
      local p_step = tonumber(p_range[3]) or 1

      for i = p_begin, p_end, p_step do
        table.insert(positions, {
          type = "test",
          path = parent.file_path,
          name = prefix .. "/" .. parent.name .. "/" .. i,
        })
      end
    elseif param_generator == "Values" then
      local p_values = vim.split(string.match(param_args, "%((.-)%)"), ",")
      for _, v in pairs(p_values) do
        table.insert(positions, {
          type = "test",
          path = parent.file_path,
          name = prefix .. "/" .. parent.name .. "/" .. vim.trim(v),
        })
      end
    elseif param_generator == "ValuesIn" then
    elseif param_generator == "Bool" then
      local p_values = { "false", "true" }
      for _, v in pairs(p_values) do
        table.insert(positions, {
          type = "test",
          path = parent.file_path,
          name = prefix .. "/" .. parent.name .. "/" .. v,
        })
      end
    end
  end

  return positions
end

function gtest.build_position(file_path, source, captured_nodes)
  local position

  if captured_nodes["test.name"] then
    ---@type string
    local suite = vim.treesitter.get_node_text(captured_nodes["test.suite"], source)
    local name = vim.treesitter.get_node_text(captured_nodes["test.name"], source)
    local range = { captured_nodes["test.definition"]:range() }

    position = {
      type = "test",
      path = file_path,
      name = suite .. "." .. name,
      range = range,
    }
  elseif captured_nodes["namespace.name"] then
    ---@type string
    local name = vim.treesitter.get_node_text(captured_nodes["namespace.name"], source)
    local range = { captured_nodes["namespace.definition"]:range() }

    if name == "TEST_P" then
      local suite = vim.treesitter.get_node_text(captured_nodes["namespace.suite"], source)
      local test = vim.treesitter.get_node_text(captured_nodes["namespace.test"], source)
      name = suite .. "." .. test
      local p_positions = gtest.build_parameterized(source, {
        suite = suite,
        name = name,
        file_path = file_path,
      })

      if p_positions[1] then
        position = {
          {

            type = "namespace",
            path = file_path,
            name = name,
            range = range,
          },
        }
        for _, p_pos in pairs(p_positions) do
          table.insert(position, p_pos)
        end
      end
    else
      position = {
        type = "namespace",
        path = file_path,
        name = name,
        range = range,
      }
    end
  end

  return position
end

function gtest.parse_positions(path)
  local lib = require("neotest.lib")
  local opts = { build_position = "require('neotest-ctest.framework.gtest').build_position" }
  return lib.treesitter.parse_positions(path, gtest.query, opts)
end

return gtest
