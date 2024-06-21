local assert = require("luassert")
local nio = require("nio")
local it = nio.tests.it

describe("with neotest configured", function()
  local utils = require("tests.integration.utils")

  it("check adapter is enabled", function()
    local state = utils.setup()
    local tree = state.neotest.state.positions(state.adapter_id)
    assert.are.same(state.neotest.state.adapter_ids(), { state.adapter_id })
    assert.is_not_nil(tree)
  end)
end)
