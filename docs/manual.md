# enough-nvim manual

## Install

```sh
cd ~/.config/nvim
./bin/install.sh
```

The core installer handles Neovim, plugins, and plugin runtime requirements only.
It never invokes `sudo` or a distro package manager. Install language tools explicitly:

```sh
./bin/install.sh
./bin/lang/python.sh
./bin/lang/c.sh
./bin/lang/cpp.sh
```

The Python script asks before installing optional debug and REPL tools. Use
`--minimal` to skip them or `--all` to install them without prompts.

```sh
./bin/install.sh --check
./bin/install.sh --test
```

## Enable features

Edit `lua/modules/init.lua`, then restart Neovim and run `:Lazy sync`.

```lua
local M = {
  ui = true,
  editing = true,
  navigation = true,
  coding = true,
  terminal = true,
  repl = true,
  debug = true,
  git = true,
  project = true,
  school42 = true,
}
```

## Enable languages

Edit `lua/config/languages.lua`. Python, C, and C++ are enabled by default.
Each enabled profile declares the tools used by LSP, formatting, debugging,
and REPL integration. YAML has its own profile instead of being bundled with shell tools.

## Keymap manual

Run any of these inside Neovim:

```text
<leader>?
<leader>fk
:KeymapManual
```

The picker shows the mappings that are active in the current session. Pause after
`<leader>` for Mini Clue when you only need to see the next available keys. The
manual is read-only, on-demand, and does not modify or execute mappings.

## Window maximize

`<leader>wm` toggles the current split between its normal size and a maximized
view without destroying the surrounding layout. Slimline displays `MAX` while
the current tab is maximized. Use `<leader>wo` only when you deliberately want
to close every other split.

## Learning mode

`<leader>tm` disables coding assistance for the current buffer while keeping
syntax colors, normal editing, terminal execution, and manual REPL use. Disabling
it restores the exact assistance states from beforehand.

## Python exploration

The Python REPL first checks the active virtual environment, then the project `.venv`. In a uv project it can launch a project-aware `ptipython`; otherwise
it follows the global fallback order:

```text
ptipython → ipython → ptpython → python
```

Use `<leader>r` mappings to open the REPL and send a line, selection, block, or
file. Python `# %%` markers define sendable code cells.

## Performance

Blink requires its Rust fuzzy matcher. Stable tags download the prebuilt library; the core installer builds it with Cargo only if needed. Check it with:

```vim
:checkhealth blink.cmp
:Lazy profile
```

The first command verifies the matcher; the second shows actual startup costs. Avoid
changing loading events based only on folklore, a resource Neovim configurations
already possess in industrial quantities.

## Health

Inside Neovim:

```vim
:ConfigHealth
:checkhealth snacks
:checkhealth mason
:checkhealth vim.lsp
```

From the shell:

```sh
./bin/install.sh --test
```
