# nvim

A practical Neovim configuration for Python, C/C++, and 42-school work. It is
small enough to read in one sitting: two directories, one switch, and no layer
of machinery deciding what is allowed to exist.

## Quick Start

```sh
# 1. Install core editor (Neovim, plugins, runtime deps)
./bin/install.sh

# 2. Install language tooling (run only what you need)
./bin/lang/python.sh    # basedpyright, flake8, autopep8, docformatter (+ optional debugpy, IPython)
./bin/lang/c.sh         # clangd, codelldb, c_formatter_42, norminette
./bin/lang/cpp.sh       # clangd, codelldb (shares C tooling)

# 3. Verify everything works
nvim --headless +ConfigHealth +qa
```

## Layout

```
init.lua                 → leaders, then require('config')
lua/config/              → shared behavior (not plugins)
  ├── init.lua           → startup orchestration
  ├── options.lua        → editor options
  ├── autocmds.lua       → automatic behavior & filetype options
  ├── diagnostics.lua    → diagnostic display configuration
  ├── assistance.lua     → per-buffer assistance toggles
  ├── learning.lua       → learning mode (disables all assistance)
  ├── minimal.lua        → minimal mode (hides UI, keeps features)
  ├── keymaps/           → all user-facing mappings
  │   ├── init.lua       → registry & manual
  │   ├── general.lua    → non-leader mappings
  │   ├── leader-*.lua   → one file per <leader> prefix
  │   └── buffer.lua     → buffer-local (LSP, gitsigns, REPL)
  ├── lsp.lua            → LSP server config & attach logic
  ├── lazy.lua           → lazy.nvim bootstrap
  ├── langs.lua          → THE switch: enabled languages & tools
  ├── health.lua         → health checks (derived from langs)
  └── icons.lua          → semantic icons only
lua/plugins/             → plugin specs (one file per feature area)
  ├── ui.lua             → colorscheme, statusline, maximize, cmdline
  ├── snacks.lua         → shared primitives (picker, terminal, git, notify)
  ├── coding.lua         → Mason, Blink, conform, nvim-lint, fidget, illuminate
  ├── editing.lua        → mini.nvim, treesitter, textobjects, comments, markdown, undotree
  ├── navigation.lua     → Oil, Flash, todo-comments, grug-far
  ├── git.lua            → gitsigns, diffview
  ├── project.lua        → overseer, persistence
  ├── terminal.lua       → terminal workflow & last-terminal
  ├── ai.lua             → 99 (explicit AI)
  ├── repl.lua           → Iron REPL
  ├── debug.lua          → nvim-dap + adapters
  └── school42.lua       → 42-header, norminette
bin/
  ├── install.sh         → core editor + plugin runtime deps
  ├── mason_install.lua  → Mason package installer
  └── lang/              → one installer per language
tests/                   → regression tests
docs/                    → documentation
```

## The One Switch: `lua/config/langs.lua`

This is the **only** configuration switch in the entire setup. Each profile declares
a language's LSP server, formatters, linters, debugger, and REPL chain. Everything
else derives from it:

| Consumer | Reads from profile |
|----------|-------------------|
| `config/lsp.lua` | `profile.lsp` — starts server if binary exists |
| `plugins/coding.lua` | `profile.formatters`, `profile.linters` |
| `plugins/debug.lua` | `profile.debugger` |
| `plugins/repl.lua` | `profile.repl` |
| `plugins/school42.lua` | `profile.norm` |
| `config/keymaps/` | whether features exist at all |
| `config/health.lua` | all of the above — reports what's missing |
| `bin/lang/<name>.sh` | same tools, installed explicitly |

**To change what's enabled:** edit `M.enabled` in `langs.lua`.
**To try a language for one session without editing:**

```sh
nvim --cmd "lua vim.g.enough_languages={python=false,c=false,cpp=false}"
```

**Adding a language = 2 edits:**
1. Profile in `langs.lua` + line in `M.enabled`
2. Script in `bin/lang/<name>.sh`

## Editor Modes

| Mode | Key | Command | What it does |
|------|-----|---------|--------------|
| **Minimal** | `<leader>mm` / `<leader>mt` | `:ModeMinimal` / `:ModeToggle` | Hides statusline, numbers, signs, folds, colorcolumn, whitespace — keeps all features |
| **Normal** | `<leader>mn` | `:ModeNormal` | Restores exact previous interface |
| **Learning** | `<leader>ml` / `<leader>tm` | `:ModeLearnToggle` | Disables diagnostics, LSP, completion, format-on-save, inlay hints — keeps syntax — restores exact prior state |

## Key Groups

```
<leader>a   whole buffer          <leader>q   problems & lists
<leader>b   buffers               <leader>r   REPL
<leader>c   code                  <leader>t   toggles & learning
<leader>d   debug                 <leader>u   undo tree
<leader>f   find & files          <leader>w   windows
<leader>g   git                   <leader>x   terminal
<leader>i   AI (99)               <leader>4   42-school
<leader>m   editor modes          s / S     Flash jump / select
<leader>p   projects & sessions   ys/ds/cs  surround add/delete/replace
```

**Discover keys:** `<leader>?` or `:KeymapManual` (searchable picker)
**Hint next keys:** Pause after `<leader>` (Mini Clue)

## Performance

- **Startup:** ~30ms (measured with `nvim --headless +qa`)
- **Eager plugins (correctness requires it):** blink.cmp, nvim-treesitter, snacks.nvim, slimline.nvim, mason.nvim
- **Lazy/`VeryLazy` everything else**
- **Blink Rust matcher:** Prebuilt from tagged releases; Cargo compile only as fallback
- **No update checks, no config-change notifications**
- **Netrw & gzip disabled** (Oil replaces netrw)

Profile with `:Lazy profile` — optimize from measurement, not folklore.

## Icons

Assumes a Nerd Font. The config owns only semantic icons (diagnostics, state, window
titles, TODO markers, debugger signs). File/LSP-kind glyphs come from `mini.icons`.
Snacks and Mini Clue use their defaults — no custom decoration layer.

## Documentation

| File | Purpose |
|------|---------|
| `docs/ARCHITECTURE.md` | Architecture principles, module structure, invariants |
| `docs/MANUAL.md` | Complete user manual |
| `docs/EXTENDING.md` | How to add languages, plugins, tools |
| `docs/PERFORMANCE.md` | Profiling, optimization guide |
| `docs/KEYMAPS.md` | Complete keymap reference |
| `docs/TOOLCHAINS.md` | Installer details |

Run `:ConfigManual` inside Neovim to open `docs/MANUAL.md`.