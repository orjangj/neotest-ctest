# neotest-ctest

<!-- TODO:
    - TOC in README
    - Document nice features: framework auto-detection, ctest test directory detection
    - Document limitations (only one test_dir supported)
    - Document known issues (file/dir incorrectly marked as passed when all tests are skipped)
    - Move all ctest related functionality into its own module
      -- Check CTest version, and produce error if not larger than 3.21 (do it in setup func?)
    - Move all framework dependent functionality into its own module
        - generating positions
        - parsing positions
        - parsing results
    - Prettify ugly ctest result output
    - File management (nio.fn.tempname() and cleanup -- keep history?)
    - Error handling
    - Document functions
    - User configuration
      - extra-args: --verbose --schedule-random --timeout <time>
    - Semantic versioning and changelog
    - Contribution guide
    - Style guide  (stylua)
    - neoconf
    - Unit tests
    - Inspired by neotest-gtest and neotest-haskell
    - BUGS?
      - Passed tests should also show test results (with time to run)
      - Parametrized tests working? I.e. TEST_P in GTest

  -- Use frameworks = config.frameworks or M.supported_frameworks
  -- to allow users to select range and order of priority... or even bypass detection
  -- by setting the desired framework to work with

-- Limitations
-- No colored output: https://gitlab.kitware.com/cmake/cmake/-/issues/17620
-- JUnit compatibility: https://gitlab.kitware.com/cmake/cmake/-/issues/22478


-->

> Still Work-in-progress, but the docs illustrates the roadmap for this plugin.
> This comment will be removed once the adapter is ready for use.

[Neotest](https://github.com/nvim-neotest/nvim-neotest) adapter for C/C++ using
[ctest](https://cmake.org/cmake/help/latest/manual/ctest.1.html) as a test
runner.

This adapter has been inspired by
[neotest-gtest](https://github.com/alfaix/neotest-gtest).

## Supported Test Frameworks

- [GoogleTest](https://github.com/google/googletest): Supports macros `TEST`, `TEST_F`
  and `TEST_P`

## Installation

Requires:

- Tree-sitter parser for C++ to be installed.
- CMake v.3.21 or higher (CTest comes bundled with CMake)

See also:
[neotest installation instructions](https://github.com/nvim-neotest/neotest#installation).

The following example uses [`lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    -- ...,
    "orjangj/neotest-ctest",
  }
}
```

## Usage

```lua
require("neotest").setup({
  adapters = {
    require("neotest-ctest")
  }
})
```

## Limitations

- Does not compile the source and tests.
  [cmake-tools](https://github.com/Civitasv/cmake-tools.nvim) is highly
  recommended as a companion plugin to manage compilation of tests.
- Attempts to auto-detect the CTest test directory. For Multi-config
  projects, it will select the first CTest enabled configuration found.
- Does not support the debugging feature of neotest + nvim-dap (yet)
- Not configurable (yet)
