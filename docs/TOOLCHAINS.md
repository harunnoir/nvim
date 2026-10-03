# Toolchains

The installers follow a narrow split:

```text
bin/install.sh       Neovim, plugins, and plugin runtime requirements
bin/lang/*.sh        explicitly requested language tooling
```

Everything reuses commands already on `PATH`, keeps fallbacks user-local, and
never uses `sudo` or a distro package manager.

## Core Installer (`bin/install.sh`)

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

### Usage

```sh
./bin/install.sh           # install core
./bin/install.sh --check   # report core commands without changing anything
./bin/install.sh --test    # run startup and installer tests
```

### What It Does

1. **Bootstrap checks** — git, curl/wget, tar, gzip, unzip, GNU tar
2. **Neovim** — downloads 0.12.4 release to `~/.local/share/nvim/neovim/`, symlinks to `~/.local/bin/nvim`
3. **Plugins** — `Lazy! sync` via headless Neovim
4. **Blink Rust matcher** — verifies prebuilt library, compiles with Cargo if missing
5. **Mason packages** — ripgrep, fd, tree-sitter-cli, lazygit (via `ensure_mason`)
6. **C compiler** — verifies cc/gcc/clang exists for Tree-sitter

### Mason Integration

`ensure_mason(package, command...)` installs a Mason package only if the
command(s) are missing. Uses `bin/mason_install.lua` for headless installation.

```lua
-- bin/mason_install.lua
M.install(name, force)
```

## Language Installers (`bin/lang/*.sh`)

Run only the profiles you use:

```sh
./bin/lang/python.sh
./bin/lang/c.sh
./bin/lang/cpp.sh
```

Every language script installs the tools named in that language's profile in
`lua/config/langs.lua`, so the script and the editor cannot disagree about what a
language needs.

### Python (`bin/lang/python.sh`)

```sh
./bin/lang/python.sh --minimal   # basedpyright, flake8, autopep8, docformatter, parser
./bin/lang/python.sh --all       # + debugpy, IPython, ptpython, ptipython
./bin/lang/python.sh             # interactive prompts
```

Uses `uv` for Python-native tools (no npm required). REPL prefers active
virtualenv → project `.venv` → `uv run` → global fallbacks.

### C (`bin/lang/c.sh`)

```sh
./bin/lang/c.sh
```

Installs: clangd, c_formatter_42, codelldb, norminette, Tree-sitter parsers (c, make)

### C++ (`bin/lang/cpp.sh`)

```sh
./bin/lang/cpp.sh
```

Sources `c.sh` for shared tooling, adds C++ compiler check and cpp parser.

### Adding a Language Installer

1. Create `bin/lang/<name>.sh` following the template in `EXTENDING.md`
2. Use `ensure_mason` for LSP/DAP, `ensure_uv_tool` for Python tools
3. Call `install_parsers` for Tree-sitter
4. Profile in `langs.lua` must match what the script installs

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `XDG_BIN_HOME` | `~/.local/bin` | User bin directory |
| `XDG_DATA_HOME` | `~/.local/share` | User data directory |
| `NVIM_APPNAME` | `basename(config_dir)` | Neovim config namespace |
| `NVIM_VERSION` | `0.12.4` | Neovim version to install |
| `NVIM` | `nvim` | Neovim binary to use |

## Verification

```sh
# Check core installation
./bin/install.sh --check

# Check language tooling
nvim --headless +ConfigHealth +qa

# Full test suite
make check
```

## Design Principles

1. **User-local only** — no system directories touched
2. **Explicit opt-in** — language tools installed by separate, explicit commands
3. **Single source of truth** — `langs.lua` profiles drive both editor config and installers
4. **Reuse over install** — `ensure_mason`/`ensure_uv_tool` skip if command exists
5. **No distro packages** — avoids version skew and permission issues