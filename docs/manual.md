# nvim manual

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

## Enable languages

Edit `lua/config/langs.lua`. Python, C, and C++ are enabled by default. Each
profile declares the LSP server, formatters, linters, debugger, and REPL chain
for its language, and everything else is derived from it: which servers start,
which tools conform and lint, which debug adapter loads, which mappings exist,
and what `:ConfigHealth` reports.

There is no plugin switch. A plugin is installed because it is written in a file
under `lua/plugins/`, and removing that line removes the plugin.

To try a language for one session without editing anything:

```sh
nvim --cmd "lua vim.g.enough_languages={python=false,c=false,cpp=false}"
```

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

Mappings that belong to one buffer are installed by the plugin that owns that
buffer, from `lua/config/keymaps.lua`: `gd` and friends once a server attaches,
`]h`/`[h` and `<leader>gh` in a Git buffer, `q` in a read-only window, and
`Ctrl-\` inside the REPL.

## Window maximize

`<leader>wm` toggles the current split between its normal size and a maximized
view without destroying the surrounding layout. Slimline displays `MAX` while
the current tab is maximized. Use `<leader>wo` only when you deliberately want
to close every other split.

## Comments

Comment.nvim provides line (`gc`) and block (`gb`) comments:

```text
gcc  Toggle the current line        gbc  Toggle the current line as a block
gc   Toggle a linewise region      gb   Toggle a blockwise region
gco  Add a comment on the next line
gcO  Add a comment on the previous line
gcA  Add a comment at the end of line
```

`gc` and `gb` also work as operators (`gcw`, `gb}`), with text objects
(`gba{`), and in visual mode. Counts and repeat (`.`) are supported.

## Undo history

`<leader>uu` opens the Undotree visualizer for the undo history of the current
buffer. Close it with `<Esc>` or `q`.

## Editor assistance

These load only when they are needed, so they cost nothing at startup:

- **fidget.nvim** shows a progress spinner while an LSP server attaches or works.
- **vim-illuminate** highlights other uses of the symbol under the cursor, after
  a short delay and only once a symbol repeats, so it never floods the screen.
- **nvim-dap-virtual-text** prints variable values inline while stepping through
  a debugging session.

Editor moves stay on existing keys: `Alt+h/j/k/l` moves the visual selection
(`]e`/`[e` still move whole lines) and `gS` toggles a one-liner into an expanded
argument list.

## Editor modes

Use `<leader>mm` for a distraction-free code view that preserves all splits,
editing features, and language tools. It hides editor chrome without maximizing
or closing a window. Use `<leader>mn` to restore the exact normal interface, or
`<leader>mt` to toggle between them. The command equivalents are `:ModeMinimal`,
`:ModeNormal`, and `:ModeToggle`.

## Learning mode

`<leader>tm` disables coding assistance for the current buffer while keeping
syntax colors, normal editing, terminal execution, and manual REPL use. Disabling
it restores the exact assistance states from beforehand.

## Python exploration

The Python REPL checks the active virtual environment, then the project `.venv`,
then a project-aware `uv run`, and only then the global fallbacks:

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
:checkhealth config
:checkhealth blink.cmp
:Lazy profile
```

`:ConfigHealth` reports what the enabled languages asked for and which of those
tools are actually installed, so a warning there names the script that installs
it.

From the shell:

```sh
./bin/install.sh --test
```
