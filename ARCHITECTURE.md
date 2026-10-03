# Enhanced Architecture Design

## Design Principles

1. **Single Source of Truth**: `lua/config/langs.lua` is the ONLY configuration switch
2. **Explicit Over Implicit**: Features exist because a line says so, not because of side effects
3. **Separation of Concerns**: Each module has one clear responsibility
4. **Performance by Default**: Lazy-load everything except what correctness requires at startup
5. **Discoverability**: All user-facing keys documented and searchable
6. **Testability**: Every behavior can be verified in isolation

## Module Structure

```
init.lua                    → leaders + require('config')
lua/config/
  ├── init.lua              → startup orchestration (only)
  ├── options.lua           → editor options (no logic)
  ├── autocmds.lua          → automatic behavior (no options)
  ├── diagnostics.lua       → diagnostic configuration (extracted from toggles)
  ├── assistance.lua        → per-buffer assistance toggles (extracted from toggles)
  ├── learning.lua          → learning mode logic (extracted from toggles)
  ├── minimal.lua           → minimal mode logic (extracted from toggles)
  ├── keymaps/
  │   ├── init.lua          → keymap registration & manual
  │   ├── general.lua       → non-leader mappings
  │   ├── leader-a.lua      → whole buffer
  │   ├── leader-b.lua      → buffers
  │   ├── leader-c.lua      → code
  │   ├── leader-d.lua      → debug
  │   ├── leader-f.lua      → find/files
  │   ├── leader-g.lua      → git
  │   ├── leader-i.lua      → AI
  │   ├── leader-m.lua      → modes (minimal/learning)
  │   ├── leader-p.lua      → projects
  │   ├── leader-q.lua      → problems/lists
  │   ├── leader-r.lua      → REPL
  │   ├── leader-t.lua      → toggles
  │   ├── leader-w.lua      → windows
  │   ├── leader-x.lua      → terminal
  │   ├── leader-4.lua      → 42-school
  │   └── buffer.lua        → buffer-local mappings (LSP, gitsigns, REPL)
  ├── lsp.lua               → LSP server config & attach logic
  ├── lazy.lua              → lazy.nvim bootstrap & config
  ├── langs.lua             → language profiles (THE switch)
  ├── health.lua            → health checks (derived from langs)
  └── icons.lua             → semantic icons only
lua/plugins/
  ├── ui.lua                → colorscheme, statusline, maximize, cmdline
  ├── snacks.lua            → shared primitives (picker, terminal, notifier, git)
  ├── coding.lua            → Mason, Blink, conform, nvim-lint, fidget, illuminate
  ├── editing.lua           → mini.nvim, treesitter, textobjects, comments, markdown, undotree
  ├── navigation.lua        → Oil, Flash, todo-comments, grug-far
  ├── git.lua               → gitsigns, diffview
  ├── project.lua           → overseer, persistence
  ├── terminal.lua          → terminal workflow (commands + last-terminal)
  ├── ai.lua                → 99 (explicit AI)
  ├── repl.lua              → Iron REPL
  ├── debug.lua             → nvim-dap + adapters
  └── school42.lua          → 42-header, norminette
bin/
  ├── install.sh            → core editor + plugin runtime deps
  ├── mason_install.lua     → Mason package installer
  └── lang/
      ├── python.sh         → Python tooling (uv-based)
      ├── c.sh              → C tooling (clangd, codelldb, 42 tools)
      └── cpp.sh            → C++ tooling (clangd, codelldb)
tests/
  ├── startup.lua           → integration tests
  ├── toggles.lua           → learning/minimal mode tests
  ├── installer.sh          → install script tests
  └── startup.sh            → test runner
docs/
  ├── README.md             → quick start + overview
  ├── ARCHITECTURE.md       → this file
  ├── MANUAL.md             → comprehensive user manual
  ├── EXTENDING.md          → how to add languages/plugins
  ├── PERFORMANCE.md        → profiling & optimization guide
  ├── KEYMAPS.md            → complete keymap reference
  └── TOOLCHAINS.md         → installer details
```

## Startup Order (Critical)

```
1. options.lua      → editor options (must be first)
2. autocmds.lua     → automatic behavior (filetype options, etc.)
3. diagnostics.lua  → diagnostic handlers (needed by first file)
4. assistance.lua   → toggle infrastructure (needed by learning mode)
5. learning.lua     → learning mode (uses assistance)
6. minimal.lua      → minimal mode (independent)
7. lazy.lua         → plugin installation & setup
8. lsp.lua          → LSP servers (attach to existing buffers)
9. keymaps.init     → user-facing mappings (last, wins conflicts)
```

## Performance Rules

| Plugin | Load Event | Reason |
|--------|------------|--------|
| blink.cmp | `VeryLazy` (but `lazy=false` for capabilities) | LSP capabilities at server config time |
| nvim-treesitter | `lazy=false` | Official setup expects startup |
| snacks.nvim | `lazy=false` | Replaces built-ins at startup |
| slimline.nvim | `lazy=false` | Statusline visible immediately |
| noice.nvim | `VeryLazy` | Command line can appear later |
| mason.nvim | `lazy=false`, priority=900 | PATH must be ready for other tools |
| Everything else | Lazy/`VeryLazy`/event-based | No correctness dependency |

## Key Invariants

1. **No plugin enable/disable list** — a plugin exists iff it's in a file under `lua/plugins/`
2. **No duplicate tool lists** — `langs.lua` is the single source
3. **All user mappings in `config/keymaps/`** — including ones plugins would install
4. **Buffer-local mappings installed by owner** — LSP, gitsigns, REPL from `keymaps/buffer.lua`
5. **Health checks derived** — `:ConfigHealth` reads `langs.lua` and `lsp.servers`
6. **Installers explicit** — `bin/lang/*.sh` install exactly what profiles declare
7. **Icons semantic** — only state/tool glyphs in `icons.lua`; file/LSP kinds from `mini.icons`

## Adding a Language (2 Edits)

1. Add profile to `langs.lua` + enable in `M.enabled`
2. Create `bin/lang/<name>.sh` installing declared tools

Everything else (LSP, formatters, linters, debugger, REPL, keymaps, health) derives automatically.