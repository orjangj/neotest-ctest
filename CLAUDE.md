# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

neotest-ctest is a Neovim plugin (Lua) that adapts the neotest testing framework for C/C++ projects using CTest. It supports GoogleTest, Catch2, doctest, and CppUTest by detecting framework includes via Tree-sitter and parsing test positions from source files.

## Commands

```bash
make setup          # Install dependencies (Tree-sitter parsers, plenary, neotest, nio)
make test           # Run all tests (unit + integration)
make unit           # Run unit tests only (plenary.busted)
make integration    # Build C++ examples then run integration tests
make build          # Build C++ integration test examples with CMake/Ninja
make clean          # Remove build artifacts
```

Unit tests use `nvim --headless` with plenary.busted. Integration tests require a CMake build step first.

## Code Style

Formatting is enforced by StyLua (checked in CI via `.github/workflows/style.yml`). Config in `.stylua.toml`: 2-space indentation, 100 column width, double quotes, Unix line endings. Run `stylua lua/ tests/` to format.

## Architecture

**Adapter interface** (`lua/neotest-ctest/init.lua`): Implements the neotest adapter protocol — `root`, `filter_dir`, `is_test_file`, `discover_positions`, `build_spec`, `results`.

**CTest runner** (`lua/neotest-ctest/ctest.lua`): Wraps CTest — discovers available tests via `ctest --show-only=json-v1`, runs selected tests using `-I` index filtering, parses JUnit XML results.

**Framework detection** (`lua/neotest-ctest/framework/init.lua`): Uses Tree-sitter queries on `#include` directives to detect which C++ test framework a file uses, then delegates to the matching module.

**Framework modules** (`lua/neotest-ctest/framework/{gtest,catch2,doctest,cpputest}.lua`): Each provides Tree-sitter queries for test macros (e.g., `TEST`, `TEST_CASE`, `SCENARIO`), position parsing, and error extraction from test output.

**Flow**: `discover_positions` detects framework → parses test positions via Tree-sitter → `build_spec` maps neotest nodes to CTest test indices → `results` parses JUnit XML and framework-specific error output.

## Testing

- Unit tests: `tests/unit/*_spec.lua` — test framework detection, position parsing, config handling
- Integration tests: `tests/integration/*_spec.lua` — end-to-end with real CMake builds
- Test data: `tests/unit/data/` contains sample C++ files for each framework
- Integration examples: `tests/integration/example/` is a CMake project with real test sources
- Unit tests are Linux-only in CI (Tree-sitter parse_positions differs on Windows)

## Key Constraints

- The plugin does NOT compile tests — it assumes an existing CMake build (e.g., from cmake-tools.nvim)
- CTestTestfile.cmake must be at most 2 levels deep from project root
- Framework detection can be ambiguous between catch2 and doctest (they share enumeration patterns)
- Error line numbers are adjusted by -1 for neotest compatibility
