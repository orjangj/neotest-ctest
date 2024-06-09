# neotest-ctest

<!-- TODO:
    - Error handling
    - Document functions
    - Support user configuration
      - extra-args (i.e. --verbose --schedule-random --timeout <time> )
      - is_test_file
      - filter_dir
      - framework selection, ordering, priority (set desired framework, or order/priority in detection algo)
        - Configurable: Set your desired framework, or set order of priority.
    - Semantic versioning, changelog and CI
    - Contribution guide
    - Style guide  (stylua)
    - neoconf
    - Unit tests
    - Document minimum versions of Neotest, GTest, Catch2... etc
    - Document usefule keybindings (short output, full output, test nearest, test file, test all)

  -- BUG: dir nodes are marked as passed in neotest summary when all tests are skipped
  -- Not sure if this is the intended behavior of Neotest, or if I'm doing something wrong.
-->

This plugin provides a [Neotest](https://github.com/nvim-neotest/nvim-neotest)
adapter for C/C++ using
[CTest](https://cmake.org/cmake/help/latest/manual/ctest.1.html) as a test
runner.

While CTest does not directly depend on the usage of CMake, this plugin assumes
you have enumerated your tests with CMake integrations of the supported test
frameworks (`gtest_discover_tests()`, `catch_discover_tests()`, etc.)

- [Supported Test Frameworks](#frameworks)
- [Features](#features)
- [Limitations](#limitations)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)

## Supported Test Frameworks

- [GoogleTest](https://github.com/google/googletest): Supports macros `TEST` and
  `TEST_F`
- [Catch2](https://github.com/catchorg/Catch2): Supports macros `TEST_CASE`,
  `TEST_CASE_METHOD`, `SCENARIO`

## Features

- Auto-detection of test framework
  - Per test file: Allows mixing frameworks if you use more than one within a
    project (i.e. subprojects)
- Auto-detection of CTest test directory (see #Limitations)
- Diagnostics (if you have enabled neotest's diagnostic option)

## Limitations

- Does not compile the source and tests.
  [cmake-tools](https://github.com/Civitasv/cmake-tools.nvim) is highly
  recommended as a companion plugin to manage compilation of tests.
- `CTestTestfile.cmake` is expected to be on path from project root (max two
  levels deep)
  - For instance `build/CTestTestfile.cmake` or
    `build/<config>/CTestTestfile.cmake`.
  - For Multi-config projects it will select the first CTest enabled
    configuration found.
- No colored output: https://gitlab.kitware.com/cmake/cmake/-/issues/17620
- Does not support the debugging feature of neotest + nvim-dap (yet)
- Not configurable (yet)

## Installation

Requires:

- Tree-sitter parser for C++ to be installed.
- CMake v3.21 or higher (CTest comes bundled with CMake)

See also:
[neotest installation instructions](https://github.com/nvim-neotest/neotest#installation).

The following example is based on
[`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    -- Other dependencies here
    "orjangj/neotest-ctest",
  },
  config = function()
    -- Optional, but recommended, if you have enabled neotest's diagnostic option
    local neotest_ns = vim.api.nvim_create_namespace("neotest")
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          -- Convert newlines, tabs and whitespaces into a single whitespace
          -- for improved virtual text readability
          local message = diagnostic.message:gsub("[\r\n\t%s]+", " ")
          return message
        end,
      },
    }, neotest_ns)

    require("neotest").setup({
      adapters = {
        -- Load with default config
        require("neotest-ctest")
      }
    })
  end
}
```

## Configuration

TODO

## Usage

_NOTE_: all usages of `require('neotest').run.run` can be mapped to a command in
your nvim config. See
[Neotest Usage](https://github.com/nvim-neotest/neotest?tab=readme-ov-file#usage)
for more.

The following example of keybindings can be used as a starting point (using
`lazy.nvim`):

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    -- Other dependencies here
    "orjangj/neotest-ctest",
  },
  keys = function()
    local neotest = require("neotest")

    return {
      { "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, desc = "Run File" },
      { "<leader>tt", function() neotest.run.run() end, desc = "Run Nearest" },
      { "<leader>tw", function() neotest.run.run(vim.uv.cwd()) end, desc = "Run Workspace" },
      {
        "<leader>tr",
        function()
          -- This will only show the output from the test framework
          neotest.output.open({ short = true, auto_close = true })
        end,
        desc = "Test Results (short)",
      },
      {
        "<leader>tR",
        function()
          -- This will show the classic CTest log output.
          -- The output usually spans more than can fit the neotest floating window,
          -- so using 'enter = true' to enable normal hjkl navigation inside the window
          -- is recommended.
          neotest.output.open({ enter = true })
        end,
        desc = "Test Results (full)",
      },
      -- Other keybindings
    }
  end,
  config = function()
    require("neotest").setup({
      adapters = {
        -- Load with default config
        require("neotest-ctest")
      }
    })
  end
}
```
