local assert = require("luassert")
local output = require("neotest-ctest.framework.output")

describe("output.normalize", function()
  it("normalizes CRLF without removing blank lines", function()
    assert.equals("first\n\nsecond\n", output.normalize("first\r\n\r\nsecond\r\n"))
  end)

  it("normalizes MSVC locations with and without a trailing colon", function()
    local text = "C:\\path with spaces\\test.cpp(12): ERROR: failed\nC:\\path\\test.hpp(34)"
    local expected = "C:\\path with spaces\\test.cpp:12: ERROR: failed\nC:\\path\\test.hpp:34"
    assert.equals(expected, output.normalize(text))
  end)

  it("preserves Unix and Windows GNU-style locations", function()
    local text = "/path/test.cpp:12: failed\nC:\\path\\test.cpp:34: failed"
    assert.equals(text, output.normalize(text))
  end)

  it("preserves parentheses in paths and assertion messages", function()
    local text = "C:\\path (123)\\test.cpp(12): ERROR: CHECK(123)\n  CHECK(123): failed"
    local expected = "C:\\path (123)\\test.cpp:12: ERROR: CHECK(123)\n  CHECK(123): failed"
    assert.equals(expected, output.normalize(text))
  end)

  it("does not normalize non-location parentheses", function()
    local text = "test.cpp(123) is an assertion value\n  value.method(123) == 1"
    assert.equals(text, output.normalize(text))
  end)
end)
