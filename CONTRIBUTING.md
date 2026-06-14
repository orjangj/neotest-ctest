# Contributing to neotest-ctest

Thanks for taking the time to contribute! This project is small and
maintained in spare time, so a little structure goes a long way. Above all,
please be respectful and constructive in issues, discussions, and reviews.

## Where things go

- **Questions / usage help** ("how do I configure this for my setup?") →
  start a [Discussion](https://github.com/orjangj/neotest-ctest/discussions).
- **Bugs and feature requests** → open an
  [Issue](https://github.com/orjangj/neotest-ctest/issues) using the matching
  template.

## Before you start

- **Bug fixes and documentation** — feel free to open a pull request directly.
- **Anything bigger** — a new test framework, a new configuration option, or a
  change in behavior — **please open an issue first** so we can agree on the
  approach before you invest your time. It saves everyone effort if the
  direction needs adjusting.

## Development setup

Lua dependencies (neotest, plenary, nvim-nio, treesitter, and the plugin
itself) are bootstrapped automatically by the test harness, so you don't need
to install them by hand. You will need:

- **Neovim**
- **[StyLua](https://github.com/JohnnyMorganz/StyLua)** — for the formatting check.
- **C/C++ toolchain**, **CMake**, and **Ninja** - for the integration tests only

The commands live in the [`Makefile`](./Makefile) — that's the source of truth:

```sh
make setup        # one-time: installs treesitter parsers into a local sandbox
make format       # format the Lua sources with StyLua
make unit         # fast, low-friction; the default while developing
make integration  # builds real CMake projects — needs CMake + Ninja
make test         # unit + integration
```

`make unit` is the low-friction default. `make integration` is heavier and
will fail without the C/C++/CMake/Ninja toolchain — if you don't have it, lean
on CI via pull requests (see below).

## Before opening a pull request

- Format your code: `make format` (this matches what CI checks).
- Run the unit tests: `make unit`.
- If you have the toolchain, run `make integration` too.
- If you changed behavior, add or update a test. The unit tests use per-framework
  fixtures under [`tests/unit/data/`](./tests/unit/data/) — mirror that pattern.

Can't run everything locally? That's fine — CI runs the full matrix (Linux,
macOS, Windows) on every pull request, so it's the real backstop.

## Opening the pull request

A pull request template will prompt you for the details that help most:

- **What** changed and **why** — written as review context, not as a commit message.
- The **related issue**, if there is one.
- **How you tested** it.

> This project uses [Conventional Commits](https://www.conventionalcommits.org/)
> together with [release-please](https://github.com/googleapis/release-please)
> to automate versioning and the changelog. PRs will be squash-merged with
> commit messages finalized at merge-time to ensure consistent release notes
> are generated.

## License

By contributing, you agree that your contributions will be licensed under the
project's [MIT License](./LICENSE).
