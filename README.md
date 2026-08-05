# enough-nvim

A practical Neovim configuration for Python, C/C++, and 42-school work. It is
small enough to understand, modular enough to extend, and deliberately avoids
turning personal dotfiles into an enterprise framework.

## Layout

```text
init.lua
lua/config/        shared editor behavior and on-demand keymap manual
lua/modules/       one file per obvious feature
bin/install.sh     user-local installer with small in-file helpers
bin/lang/          standalone language installers
tests/             small regression checks with comments explaining their value
```

Modules are straightforward:

```text
ui          colorscheme, statusline, notifications
editing     pairs, surrounds, Tree-sitter, text objects
navigation  Flash, files, buffers, search, Oil, TODO comments, Trouble
coding      Mason, completion, formatting, LSP-facing tools
terminal    Snacks terminal behavior and commands
repl        Iron REPL integration
debug       DAP and language adapters
git         Gitsigns and LazyGit
project     projects, tasks, and sessions
school42    header, Norminette, and c_formatter_42
```

## Languages

`lua/config/languages.lua` is the single readable description of enabled
languages and their LSP, formatter, debugger, and REPL tools. Python,
C, and C++ are enabled by default.

## Install

```sh
./bin/install.sh
```

The core installer reuses existing commands and installs only Neovim, plugins,
and plugin runtime requirements. It never invokes `sudo` or a distro package
manager. Language tools are explicit, separate steps:

```sh
./bin/install.sh
./bin/lang/python.sh      # asks about optional debug and REPL tools
./bin/lang/c.sh
./bin/lang/cpp.sh
```

Python modes:

```sh
./bin/lang/python.sh --minimal
./bin/lang/python.sh --all
```

Checks remain on the core installer:

```sh
./bin/install.sh --check
./bin/install.sh --test
```

## Icons

The configuration assumes a Nerd Font. `mini.icons` provides file and LSP-kind
glyphs; custom icons are limited to diagnostics, state indicators, terminal/REPL
titles, TODO markers, and debugger signs. Snacks and Mini Clue keep their normal
labels instead of carrying a separate decoration layer.

## Performance

Performance is treated as a constraint:

- Blink requires its Rust fuzzy matcher. Tagged releases download a prebuilt library; the installer compiles it with Cargo only if that download fails.
- Plugins stay lazy unless startup loading is required for correct behavior.
- Tree-sitter and Snacks remain startup-loaded because their official setup expects it.
- Smooth Snacks scrolling is disabled; `bigfile` and `quickfile` remain enabled.
- Plugin update checks and config-change notifications stay off.
- Netrw alone is disabled because Oil replaces it as the file explorer.

Use `:Lazy profile` when a real slowdown appears; optimization should follow evidence,
not produce a maze of fragile loading events.

## Main key groups

```text
<leader>a  whole-buffer actions
<leader>b  buffers
<leader>c  code
<leader>d  debug
<leader>f  find and files
<leader>g  Git
<leader>p  projects, tasks, sessions
<leader>q  problems and lists
<leader>r  REPL
<leader>t  toggles and learning mode
<leader>w  windows
<leader>x  terminal
<leader>4  42-school tools

s / S       Flash jump and Tree-sitter selection
ys / ds / cs add, delete, and replace surrounds
```

Window management includes a reversible split zoom:

```text
<leader>wm  maximize or restore the current split
```

Slimline shows an icon with `MAX` while a split is maximized. The existing
focus, resize, move, equalize, and close mappings remain unchanged.

Whole-buffer shortcuts are deliberately small:

```text
<leader>aa  select all
<leader>ay  copy all
<leader>ax  cut all
```

Discover active mappings at runtime:

```text
<leader>?   searchable keymap manual
<leader>fk  searchable keymap manual
:KeymapManual
```

Pause after `<leader>` to use Mini Clue for the current key sequence. The manual
is read-only, opens only when requested, and does not create, alter, or execute mappings.

TODO comments are highlighted automatically. Use `]t` / `[t` to move between
comments and `<leader>qt` to browse project TODOs in Trouble.

Learning mode (`<leader>tm`) disables coding assistance in the current buffer
while keeping syntax colors, then restores the exact previous assistance state
when toggled off. Slimline hides disabled diagnostics and formatters instead of
reporting tools that will not actually run.

The Python REPL prefers the active virtual environment, then the project's `.venv`,
then a project-aware `uv run`, and finally the configured global fallbacks.

Run `:ConfigHealth` after installation. More detail lives under `docs/`.
