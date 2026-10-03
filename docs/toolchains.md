# Toolchains

The installers follow a narrow split:

```text
bin/install.sh       Neovim, plugins, and plugin runtime requirements
bin/lang/*.sh        explicitly requested language tooling
```

Everything reuses commands already on `PATH`, keeps fallbacks user-local, and
never uses `sudo` or a distro package manager.

## Core

The core installer checks or installs:

```text
Neovim 0.12+
Git
curl or wget
tar, gzip, GNU tar, and unzip
ripgrep and fd for navigation
Tree-sitter CLI plus an existing C compiler
Lazygit
Blink's Rust fuzzy matcher
```

Blink `1.*` releases automatically download an optimized prebuilt matcher into
`stdpath('data')/lazy/blink.cmp/target/release/`. Cargo is used only when that
download is unavailable. `trash-put` remains optional for safe Oil deletion.

## Languages

Run only the profiles you use:

```sh
./bin/lang/python.sh
./bin/lang/c.sh
./bin/lang/cpp.sh
```

Every language script installs the tools named in that language's profile in
`lua/config/langs.lua`, so the script and the editor cannot disagree about what a
language needs. The Python script asks before installing optional debugpy and
interactive REPL tools. For automation, use:

```sh
./bin/lang/python.sh --minimal
./bin/lang/python.sh --all
```

Python-native commands use `uv`, so Python support does not require Node or npm.
The REPL still prefers active and project environments so imports match the code.
Other language scripts reuse their existing runtime and install only editor-facing
servers, formatters, parsers, and adapters.
