# nvim Manual

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

## Enable Languages

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

## Keymap Manual

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
buffer, from `lua/config/keymaps/buffer.lua`: `gd` and friends once a server
attaches, `]h`/`[h` and `<leader>gh` in a Git buffer, `q` in a read-only window,
and `Ctrl-\` inside the REPL.

## Complete Keymap Reference

### General (No Prefix)

| Key | Mode | Action |
|-----|------|--------|
| `<Esc>` | n | Clear search highlight |
| `<C-s>` | n,i,x | Write file |
| `<BS>` | n | Alternate buffer |
| `j` / `k` | n,x | Screen-line movement (wrapped) |
| `<` / `>` | x | Indent/outdent keep selection |
| `p` | x | Paste without replacing register |
| `]e` / `[e` | n | Move line down/up |
| `]e` / `[e` | x | Move selection down/up |
| `<leader>uu` | n | Toggle undo tree |
| `ys` / `ds` / `cs` | n | Surround add/delete/replace |
| `yss` | n | Surround current line |
| `gsn` | n | Set surround search lines |
| `af` / `if` | x,o | Around/inside function (treesitter) |
| `ac` / `ic` | x,o | Around/inside class (treesitter) |
| `]f` / `[f` | n,x,o | Next/previous function |
| `s` | n,x,o | Flash jump |
| `S` | n,x,o | Flash treesitter select |
| `r` | o | Flash remote operator |

### `<leader>a` — Whole Buffer

| Key | Action |
|-----|--------|
| `aa` | Select whole buffer |
| `ay` | Copy whole buffer to clipboard |
| `ax` | Cut whole buffer to clipboard |

### `<leader>b` — Buffers

| Key | Action |
|-----|--------|
| `bb` | Buffer picker (Snacks) |
| `bn` / `bp` | Next/previous buffer |
| `bd` | Delete buffer (Snacks) |
| `bo` | Delete other buffers |

### `<leader>c` — Code

| Key | Action |
|-----|--------|
| `cm` | Open Mason |
| `cf` | Format buffer (conform) |
| `cf` | Format selection (visual) |
| `cu` | Colorscheme picker |

### `<leader>d` — Debug (DAP) — *requires debugger-enabled language*

| Key | Action |
|-----|--------|
| `dc` | Continue / start |
| `di` | Step into |
| `do` | Step over |
| `dO` | Step out |
| `dr` | Run last configuration |
| `dt` | Terminate |
| `db` | Toggle breakpoint |
| `dB` | Conditional breakpoint |
| `du` | Toggle debug UI (dapui) |
| `de` | Evaluate under cursor (dapui) |

### `<leader>f` — Find & Files

| Key | Action |
|-----|--------|
| `ff` | Find files (Snacks) |
| `fg` | Grep project (Snacks) |
| `fw` | Grep word under cursor (Snacks) |
| `fr` | Recent files (Snacks) |
| `fh` | Help tags (Snacks) |
| `fc` | Config files (Snacks) |
| `fe` | File explorer (Oil) |
| `-` | Open parent directory (Oil) |
| `fR` | Find and replace (GrugFar) |
| `]t` / `[t` | Next/previous TODO comment |

### `<leader>g` — Git

| Key | Action |
|-----|--------|
| `gg` | Lazygit (Snacks) |
| `gd` | Diffview open |
| `gD` | Diffview file history |
| `gv` | Diffview close |
| `go` | Open in browser (Snacks) |
| `gl` | Git log (Snacks) |
| `gs` | Git status (Snacks) |
| `gb` | Git branches (Snacks) |

### `<leader>i` — AI (99)

| Key | Action |
|-----|--------|
| `i9s` | Project code search |
| `i9v` | Edit selection (visual) |
| `i9o` | Open latest AI result |
| `i9x` | Stop AI requests |
| `i9m` | Select AI model |

### `<leader>m` — Editor Modes

| Key | Action |
|-----|--------|
| `mm` | Enter minimal mode |
| `mn` | Enter normal mode |
| `mt` | Toggle minimal mode |
| `ml` | Toggle learning mode |

### `<leader>p` — Projects, Tasks, Sessions

| Key | Action |
|-----|--------|
| `pp` | Projects picker (Snacks) |
| `pt` | Run task (Overseer) |
| `po` | Toggle task output (Overseer) |
| `pc` | Run shell command (Overseer) |
| `pa` | Task action (Overseer) |
| `ps` | Restore session (persistence) |
| `pS` | Select session (persistence) |
| `pl` | Restore last session (persistence) |

### `<leader>q` — Problems & Lists

| Key | Action |
|-----|--------|
| `qq` | Workspace diagnostics (Snacks) |
| `qb` | Buffer diagnostics (Snacks) |
| `qs` | Symbols in file (Snacks) |
| `ql` | Symbols in workspace (Snacks) |
| `qf` | Quickfix list (Snacks) |
| `qL` | Location list (Snacks) |
| `qt` | TODO comments (quickfix + Snacks) |

### `<leader>r` — REPL — *requires REPL-enabled language*

| Key | Action |
|-----|--------|
| `rt` | Toggle REPL (Iron) |
| `rf` | Focus REPL |
| `rh` | Hide REPL |
| `rr` | Restart REPL |
| `rl` | Send line |
| `rs` | Send selection (visual) |
| `rb` | Send code block |
| `rn` | Send code block and move |
| `rp` | Send paragraph |
| `ra` | Send whole file |
| `ru` | Send until cursor |

### `<leader>t` — Toggles

| Key | Feature | Scope |
|-----|---------|-------|
| `td` | Diagnostics | Buffer |
| `tv` | Virtual text | Buffer |
| `tW` | Warnings (show WARN+) | Buffer |
| `tl` | LSP | Buffer |
| `tc` | Completion | Buffer |
| `tf` | Format on save | Buffer |
| `th` | Inlay hints | Buffer |
| `tm` | Learning mode | Buffer |
| `tw` | Line wrap | Window |
| `ts` | Spelling | Window |
| `tn` | Relative numbers | Window |

### `<leader>w` — Windows

| Key | Action |
|-----|--------|
| `<C-h/j/k/l>` | Focus window |
| `<A-h/j/k/l>` | Resize window (also in terminal) |
| `wv` / `ws` | Split vertical/horizontal |
| `wc` | Close window |
| `we` | Equalize windows |
| `wo` | Keep only this window |
| `wm` | Toggle maximize (reversible) |
| `wh/j/k/l` | Move window |
| `wH/J/K/L` | Resize via leader |

### `<leader>x` — Terminal

| Key | Action |
|-----|--------|
| `<C-\>` | Toggle last terminal (also in terminal) |
| `xt` | Toggle last terminal |
| `xf` | Floating terminal |
| `xh` | Horizontal terminal |
| `xv` | Vertical terminal |
| `xd` | Terminal in file directory |
| `xp` | Terminal at project root |
| `xn` | New named terminal |
| `xl` | Select terminal |
| `xr` | Restart terminal |
| `xq` | Stop terminal |

### `<leader>4` — 42-School — *requires C/C++ with norm*

| Key | Action |
|-----|--------|
| `4h` | Insert 42 header |
| `4f` | Format to 42 norm |
| `4n` | Run Norminette |

### Terminal Mode

| Key | Action |
|-----|--------|
| `<Esc><Esc>` | Leave terminal mode |
| `<C-h/j/k/l>` | Focus window |
| `<A-h/j/k/l>` | Resize window |

## Window Maximize

`<leader>wm` toggles the current split between its normal size and a maximized
view without destroying the surrounding layout. Slimline displays `MAX` while
the current tab is maximized. Use `<leader>wo` only when you deliberately want
to close every other split.

## Comments

Comment.nvim provides line (`gc`) and block (`gb`) comments:

```text
gcc  Toggle current line        gbc  Toggle current line as block
gc   Toggle linewise region    gb   Toggle blockwise region
gco  Add comment on next line
gcO  Add comment on previous line
gcA  Add comment at end of line
```

`gc` and `gb` also work as operators (`gcw`, `gb}`), with text objects
(`gba{`), and in visual mode. Counts and repeat (`.`) are supported.

## Undo History

`<leader>uu` opens the Undotree visualizer for the undo history of the current
buffer. Close it with `<Esc>` or `q`.

## Editor Assistance

These load only when needed, so they cost nothing at startup:

- **fidget.nvim** shows a progress spinner while an LSP server attaches or works.
- **vim-illuminate** highlights other uses of the symbol under the cursor, after
  a short delay and only once a symbol repeats, so it never floods the screen.
- **nvim-dap-virtual-text** prints variable values inline while stepping through
  a debugging session.

Editor moves stay on existing keys: `Alt+h/j/k/l` moves the visual selection
(`]e`/`[e` still move whole lines) and `gS` toggles a one-liner into an expanded
argument list.

## Editor Modes

### Minimal Mode

`<leader>mm` / `<leader>mt` — distraction-free code view that preserves all
splits, editing features, and language tools. It hides editor chrome without
maximizing or closing a window.

- Statusline, cmdline, tabline hidden
- Line numbers, relative numbers, sign column, fold column hidden
- Colorcolumn, whitespace markers, cursorline, cursorcolumn hidden
- Winbar hidden

`<leader>mn` restores the exact normal interface. New splits created during
minimal mode inherit the minimal appearance and restore correctly.

### Learning Mode

`<leader>ml` / `<leader>tm` — disables coding assistance for the current buffer
while keeping syntax colors, normal editing, terminal execution, and manual REPL
use.

**Disables:** diagnostics, virtual text, warnings filter, LSP, completion,
format-on-save, inlay hints.

**Preserves:** syntax highlighting, all editing commands, terminal, REPL.

**Restores:** exact previous state of each feature (not defaults) when turned off.

**Blocked:** Manual toggles for disabled features show a warning — turn learning
mode off first.

## Python Exploration

The Python REPL checks the active virtual environment, then the project `.venv`,
then a project-aware `uv run`, and only then the global fallbacks:

```text
ptipython → ipython → ptpython → python
```

Use `<leader>r` mappings to open the REPL and send a line, selection, block, or
file. Python `# %%` markers define sendable code cells.

## Performance

Blink requires its Rust fuzzy matcher. Stable tags download the prebuilt library;
the core installer builds it with Cargo only if needed. Check it with:

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