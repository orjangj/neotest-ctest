# neotest-ctest

[Neotest](https://github.com/nvim-neotest/nvim-neotest) adapter for C/C++ using [ctest](https://cmake.org/cmake/help/latest/manual/ctest.1.html) as a test runner.

This adapter has been inspired by [neotest-gtest](https://github.com/alfaix/neotest-gtest).

## Dependencies

- [neotest](https://github.com/nvim-neotest/nvim-neotest) itself obviously
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) and parser for C++ (cpp).
- [cmake](https://cmake.org/) (ctest is bundled with cmake)

## Supports

Test frameworks:
- [googletest](https://github.com/google/googletest) (macros `TEST`, `TEST_F` and `TEST_P`).

Test capabilities: 
- Nearest
- File
- Suite

## Limitations

- Does not compile the source and tests (use something like [neovim-tasks](https://github.com/Shatur/neovim-tasks) for that).
- Assumes cmake build directory is located at `build/` relative to project root.
- No colored output log for failed tests

neotest-ctest is able to detect fixtures ("namespace" in the context of neotest)
as well, but testing capabilities is incomplete at the moment. Defaults to running
nearest test.

## Installation

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "orjangj/neotest-ctest" }
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'orjangj/neotest-ctest'
```

## Usage

```lua
require("neotest").setupt({
  adapters = {
    require("neotest-ctest")
  }
})
```

## Configuration

TODO

Some thoughts:
- Specify build directory
- Extra arguments to pass to ctest
- Debugging ([nvim-dap](https://github.com/mfussenegger/nvim-dap))

## License

MIT, see [LICENSE](https://github.com/orjangj/neotest-ctest/blob/main/LICENSE)
