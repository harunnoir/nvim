# Architecture

The configuration has two layers, and the split is the point:

```text
init.lua
  ├── lua/config/    behavior that is not a plugin
  └── lua/plugins/   plugin specifications, one file per area
```

## lua/config

Everything here would exist even if lazy.nvim did not:

```text
init.lua           startup order and the Config* commands
options.lua        editor options (no logic)
autocmds.lua       automatic behavior and filetype options
diagnostics.lua    diagnostic display configuration (single source)
assistance.lua     per-buffer assistance toggles (7 features)
learning.lua       learning mode (snapshot/restore assistance)
minimal.lua        minimal mode (hides UI, keeps features)
keymaps/           every user-facing mapping
  init.lua         keymap registry, manual, Mini Clue groups
  general.lua      non-leader mappings
  leader-a.lua     whole buffer
  leader-b.lua     buffers
  leader-c.lua     code
  leader-d.lua     debug
  leader-f.lua     find/files
  leader-g.lua     git
  leader-i.lua     AI (99)
  leader-m.lua     modes (minimal/learning)
  leader-p.lua     projects/tasks/sessions
  leader-q.lua     problems/lists
  leader-r.lua     REPL
  leader-t.lua     toggles
  leader-w.lua     windows
  leader-x.lua     terminal
  leader-4.lua     42-school
  buffer.lua       buffer-local (LSP, gitsigns, REPL)
lsp.lua            server definitions and per-buffer attach/detach
lazy.lua           lazy.nvim bootstrap and the plugin list
langs.lua          the one switch: enabled languages and their tools
health.lua         health checks derived from langs.lua
icons.lua          the semantic glyphs this config owns
```

### Startup Order (Deliberate)

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

## lua/plugins

Every file here is a Lazy spec, and `config/lazy.lua` imports the directory, so
a new file is a new feature area with no list to update. Each file owns one area:

```text
ui          colorscheme, statusline, notifications, maximize
snacks      shared primitives: picker, terminal, notifier, git tools
coding      Mason, completion, formatting, linting, LSP-facing tools
editing     pairs, surrounds, comments, Tree-sitter, undo tree
navigation  Oil, Flash, TODO comments, find and replace
git         Gitsigns and Diffview
project     tasks and per-directory sessions
terminal    terminal commands and the last-terminal workflow
ai          explicit selection edits and project code search with 99
repl        interactive code execution
debug       DAP and the adapters for the languages you enabled
school42    header, Norminette, and c_formatter_42
```

Snacks is configured once in `plugins/snacks.lua`. Everything else consumes
`Snacks.*` rather than declaring a second copy of those options.

## Rules

1. A feature exists because a line says so, never because a switch elsewhere is true.
2. `langs.lua` is the only switch; derive, do not duplicate.
3. Every user-facing mapping goes in `config/keymaps/`, including the ones a
   plugin would install for itself.
4. Add a file to `lua/plugins/` only when it owns a feature area of its own.
5. Reuse an existing command or plugin before installing anything.
6. Prefer built-in Neovim behavior when it already solves the problem.

## Derived, Not Declared

The point of `langs.lua` is that these are all the same list seen from different
sides, and none of them is written twice:

| Consumer | What it reads |
| --- | --- |
| `config/lsp.lua` | `profile.lsp`, and starts it only if the binary exists |
| `plugins/coding.lua` | `profile.formatters`, `profile.linters` |
| `plugins/debug.lua` | `profile.debugger` |
| `plugins/repl.lua` | `profile.repl` |
| `plugins/school42.lua` | `profile.norm` |
| `config/keymaps/` | whether any of the above exist at all |
| `config/health.lua` | all of them, to report what is missing |
| `bin/lang/<name>.sh` | the same tools, installed explicitly |

## UI Icons

`lua/config/icons.lua` keeps only the state and tool glyphs with no natural
source: diagnostics, learning and maximize indicators, window titles, TODO
markers, and debugger signs. File and LSP-kind glyphs come from `mini.icons`.
Snacks uses its defaults, and Mini Clue keeps plain group names, so the config
carries no separate decoration layer.

## Performance Rules

1. Lazy-load a plugin unless something correct depends on its API at startup.
2. Blink is the exception and stays eager: its LSP capabilities have to be sent
   when a server is configured, not when completion first runs.
3. Tree-sitter and Snacks stay startup-loaded because their supported setup
   expects it.
4. Prefer tagged prebuilt native components; compile only as a verified fallback.
5. Measure with `:Lazy profile` before adding loading conditions.

### Plugin Load Strategy

| Plugin | Load Event | Reason |
|--------|------------|--------|
| blink.cmp | `lazy=false` | LSP capabilities at server config time |
| nvim-treesitter | `lazy=false` | Official setup expects startup |
| snacks.nvim | `lazy=false` | Replaces built-ins at startup |
| slimline.nvim | `lazy=false` | Statusline visible immediately |
| mason.nvim | `lazy=false`, priority=900 | PATH must be ready for other tools |
| noice.nvim | `VeryLazy` | Command line can appear later |
| Everything else | Lazy/`VeryLazy`/event-based | No correctness dependency |