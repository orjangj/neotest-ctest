<!-- prettier-ignore-start -->

<div align="center">
  <h1>neotest-ctest</h1>
  <p>
    <strong>
      A <a href="https://github.com/nvim-neotest/neotest">neotest</a> adapter for C/C++
      using <a href="https://cmake.org/cmake/help/latest/manual/ctest.1.html">CTest</a>
      as a test runner
    </strong>
  </p>

[![Neovim][neovim-shield]][neovim-url]
[![Lua][lua-shield]][lua-url]
[![CTest][ctest-shield]][ctest-url]
![cpp-shield]

[![MIT License][license-shield]][license-url]
[![Issues][issues-shield]][issues-url]
[![Build Status][ci-shield]][ci-url]

</div>

<!-- prettier-ignore-end -->

## Quick links

- [Features](#features)
- [Limitations](#limitations)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)

## Features

- Supported Test Frameworks
  - [GoogleTest](https://github.com/google/googletest) (v1.11.0+): Supports
    macros `TEST`, `TEST_F` and `TEST_P`
    - For `TEST_P`, only `Range`, `Values` and `Bool` parameter generators are
      supported. The name generator is not supported either. See
      [INSTANTIATE_TEST_SUITE_P](https://google.github.io/googletest/reference/testing.html#INSTANTIATE_TEST_SUITE_P)
      for more.
  - [Catch2](https://github.com/catchorg/Catch2) (v3.3.0+): Supports macros
    `TEST_CASE`, `TEST_CASE_METHOD`, `SCENARIO`
- Automatically detects test framework used in a test file
  - Using multiple test frameworks is supported as each test file is evaluated
    separately
  - What frameworks to include in the detection is configurable
- Automatically detects CTest test directory (see [limitations](#limitations))
- Parses test results and displays errors as diagnostics (if you have enabled
  neotest's diagnostic option)

> _The framework versions listed above are the ones that have been tested, but
> older versions may work as well._

## Limitations

- Does not compile any source or tests
  ([cmake-tools](https://github.com/Civitasv/cmake-tools.nvim) is highly
  recommended as a companion plugin).
- While CTest does not directly depend on the usage of CMake, this plugin
  assumes you have enumerated your tests with CMake integrations such as
  `gtest_discover_tests()`, `catch_discover_tests()`, etc.
- `CTestTestfile.cmake` is expected to be on path from project root (max two
  levels deep)
  - For instance `<dir>/CTestTestfile.cmake` or
    `<dir>/<config>/CTestTestfile.cmake`.
  - For multi-config projects, the first CTest enabled configuration found will
    be selected.
- Does not support neotest's `dap` strategy for debugging tests (yet)

## Requirements

- [Neovim](https://github.com/neovim/neovim) v0.9.1+, v0.10.x, or nightly.
- [nvim-neotest](https://github.com/nvim-neotest/nvim-neotest) v5.0.0+
- Tree-sitter parser for C++ to be installed (preferably latest).
- CMake v3.21 or higher (CTest is bundled with CMake)

## Installation

See
[Neotest Installation Instructions](https://github.com/nvim-neotest/neotest#installation).

The following example is based on
[`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Other neotest dependencies here
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
        require("neotest-ctest").setup({})
      }
    })
  end
}
```

## Configuration

```lua
require("neotest-ctest").setup({
  -- fun(string) -> string: Find the project root directory given a current directory
  -- to work from.
  root = function(dir)
    -- by default, it will use neotest.lib.files.match_root_pattern with the following entries
    return require("neotest.lib").files.match_root_pattern(
      -- NOTE: CMakeLists.txt is not a good candidate as it can be found in
      -- more than one directory
      "CMakePresets.json",
      "compile_commands.json",
      ".clangd",
      ".clang-format",
      ".clang-tidy",
      "build",
      "out",
      ".git"
    )(dir)
  end
  ),
  -- fun(string) -> bool: Takes a file path as string and returns true if it contains tests.
  -- This function is called often by neotest, so make sure you don't do any heavy duty work.
  is_test_file = function(file)
    -- by default, returns true if the file stem ends with _test and the file extension is
    -- one of cpp/cc/cxx.
  end,
  -- fun(string, string, string) -> bool: Filter directories when searching for test files.
  -- Best to keep this as-is and set per-project settings in neotest instead.
  -- See :h neotest.Config.discovery.
  filter_dir = function(name, rel_path, root)
    -- If you don't configure filter_dir through neotest, and you leave it as-is,
    -- it will filter the following directories by default: build, cmake, doc,
    -- docs, examples, out, scripts, tools, venv.
  end,
  -- What frameworks to consider when performing auto-detection of test files.
  -- Priority can be configured by ordering/removing list items to your needs.
  -- By default, each test file will be queried with the given frameworks in the
  -- following order.
  frameworks = { "gtest", "catch2" },
  -- What extra args should ALWAYS be sent to CTest? Note that most of CTest arguments
  -- are not expected to be used (or work) with this plugin, but some might be useful
  -- depending on your needs. For instance:
  --   extra_args = {
  --     "--stop-on-failure",
  --     "--schedule-random",
  --     "--timeout",
  --     "<seconds>",
  --   }
  -- If you want to send extra_args for one given invocation only, send them to
  -- `neotest.run.run({extra_args = ...})` instead. see :h neotest.RunArgs for details.
  extra_args = {},
})
```

It's possible to configure the adapter per project using Neotest's `projects`
option if you need more fine-grained control:

```lua
require("neotest").setup({
  -- other options
  projects = {
    ["~/path/to/some/project"] = {
      discovery = {
        filter_dir = function(name, rel_path, root)
          -- Do not look for tests in `build` folder for this specific project
          return name ~= "build"
        end,
      },
      adapters = {
        require("neotest-ctest").setup({
          is_test_file = function(file_path)
            -- your implementation
          end,
          frameworks = { "catch2" },
        }),
      },
    },
  },
})
```

## Usage

See
[Neotest Usage](https://github.com/nvim-neotest/neotest?tab=readme-ov-file#usage).
The following example of keybindings can be used as a starting point:

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Other neotest dependencies here
    "orjangj/neotest-ctest",
  },
  keys = function()
    local neotest = require("neotest")

    return {
      { "<leader>tf", function() neotest.run.run(vim.fn.expand("%")) end, desc = "Run File" },
      { "<leader>tt", function() neotest.run.run() end, desc = "Run Nearest" },
      { "<leader>tw", function() neotest.run.run(vim.loop.cwd()) end, desc = "Run Workspace" },
      {
        "<leader>tr",
        function()
          -- This will only show the output from the test framework
          neotest.output.open({ short = true, auto_close = true })
        end,
        desc = "Results (short)",
      },
      {
        "<leader>tR",
        function()
          -- This will show the classic CTest log output.
          -- The output usually spans more than can fit the neotest floating window,
          -- so using 'enter = true' to enable normal navigation within the window
          -- is recommended.
          neotest.output.open({ enter = true })
        end,
        desc = "Results (full)",
      },
      -- Other keybindings
    }
  end,
  config = function()
    require("neotest").setup({
      adapters = {
        -- Load with default config
        require("neotest-ctest").setup({})
      }
    })
  end
}
```

<!-- MARKDOWN LINKS & IMAGES -->
<!-- prettier-ignore-start -->

[neovim-shield]: https://img.shields.io/badge/NeoVim-%23228B22.svg?&style=for-the-badge&logo=neovim&logoColor=white
[neovim-url]: https://neovim.io/
[lua-shield]: https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white
[lua-url]: https://www.lua.org/
[ctest-shield]: https://img.shields.io/badge/CTest-%23003765.svg?style=for-the-badge&logo=cmake&logoColor=white
[ctest-url]: https://cmake.org/cmake/help/latest/manual/ctest.1.html
[cpp-shield]: https://img.shields.io/badge/C/C++-%2300599C.svg?&style=for-the-badge&logo=c%2B%2B&logoColor=white
[issues-shield]: https://img.shields.io/github/issues/orjangj/neotest-ctest.svg?style=for-the-badge
[issues-url]: https://github.com/orjangj/neotest-ctest/issues
[license-shield]: https://img.shields.io/github/license/orjangj/neotest-ctest.svg?style=for-the-badge
[license-url]: https://github.com/orjangj/neotest-ctest/blob/master/LICENSE
[ci-shield]: https://img.shields.io/github/actions/workflow/status/orjangj/neotest-ctest/test.yml?style=for-the-badge
[ci-url]: https://github.com/orjangj/neotest-ctest/actions/workflows/test.yml

<!-- prettier-ignore-end -->
