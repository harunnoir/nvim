# Extending nvim

## Add a Plugin

1. Put its Lazy spec in the file in `lua/plugins/` that owns the area.
   A new file is picked up automatically; there is no list to register it in.

2. Put its user-facing mappings in the matching section of
   `config/keymaps/`. If the plugin would install its own, set `keys = false`
   and map it here instead.

3. If it needs an external command, add it to `bin/install.sh` when it is needed
   by the editor itself, or to `bin/lang/<language>.sh` when it belongs to one
   language. Never use `sudo` or a distro package manager.

## Add a Language

Two edits, and the rest follows:

1. Add a profile to `M.profiles` and a line to `M.enabled` in
   `lua/config/langs.lua`. The file contains a complete worked example.

2. Add `bin/lang/<language>.sh`.

That is the whole job. The profile decides which server `config/lsp.lua` starts,
which formatters conform runs, which linters run, which debugger adapter loads,
which REPL chain `plugins/repl.lua` prefers, whether the 42-school mappings
appear, and what `:ConfigHealth` reports. If you find yourself editing one of
those files to add a language, the profile is missing a field.

### Profile Fields

```lua
go = {
    filetype = { 'go', 'gomod' },      -- filetypes this profile applies to
    lsp = 'gopls',                      -- key in config/lsp.lua
    linters = { 'revive' },             -- Mason package names for nvim-lint
    formatters = { 'gofumpt', 'goimports' }, -- Mason package names for conform
    debugger = { name = 'delve', command = 'dlv' }, -- for nvim-dap
    repl = { 'go-repl' },               -- first available wins (Iron)
    norm = true,                        -- 42 norm applies to this language
}
```

Keep every field factual: each one should be consumed somewhere. A field nothing
reads is a field to delete.

### Language Installer Template

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
source "$ROOT/bin/install.sh"

install_language() {
    language_bootstrap
    info 'Installing <language> tools'
    # ensure_mason <package> <command>    # for Mason packages (LSP, DAP)
    # ensure_uv_tool <command> <package>  # for Python tools via uv
    # install_parsers <language>          # Tree-sitter parsers
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
```

## Test a Language for One Session

```sh
nvim --cmd "lua vim.g.enough_languages={go=true,python=false}"
```

Overrides must name a language that has a profile, and must be booleans; anything
else is an error rather than a silent no-op.

## Add a Keymap

1. Find the right section in `config/keymaps/` (by `<leader>` prefix or `general.lua`).
2. Add the mapping using `map(mode, lhs, rhs, opts('Description'))`.
3. If it's a `<leader>` prefix group, add it to `M.clues()` in `keymaps/init.lua`.

## Add a Toggle

1. Add a feature entry to `assistance.features` in `config/assistance.lua`:
   ```lua
   {
       name = 'my_feature',
       key = 'x',  -- <leader>tx
       is_on = function(bufnr) return ... end,
       set = function(bufnr, on) ... end,
   }
   ```
2. The keymap `<leader>tx` is created automatically by `keymaps/leader-t.lua`.
3. Learning mode will automatically include it in its snapshot/restore.

## Add a Diagnostic Source

Diagnostics are configured in `config/diagnostics.lua`. The severity filter
reads live state from `assistance.is_warnings_enabled(bufnr)`. To add a new
diagnostic source, ensure it integrates with `vim.diagnostic` — no config
changes needed.

## Add a Colorscheme

Append to the theme table at the bottom of `plugins/ui.lua`:
```lua
for _, theme in ipairs({
    'existing/themes',
    'new/colorscheme',  -- add here
}) do
    specs[#specs + 1] = { theme, lazy = false }
end
```

Themes load at startup so `<leader>cu` (Snacks picker) can find them. They cost
one git checkout and nothing at runtime. None applies itself — you choose.

## Add a Tree-sitter Parser

1. Add parser name to `install_parsers` in the language's `bin/lang/*.sh`.
2. The parser auto-loads when a file of that filetype opens (via autocmd in
   `plugins/editing.lua`).

## Add a Formatter/Linter

1. Add Mason package name to `profile.formatters` or `profile.linters` in `langs.lua`.
2. If formatter needs custom args, add to `formatters` table in `plugins/coding.lua`.
3. Run `./bin/lang/<language>.sh` to install.
4. `:ConfigHealth` will verify it.

## Add a Debug Adapter

1. Add `debugger` field to profile in `langs.lua`.
2. If adapter needs a nvim-dap bridge plugin (e.g., `nvim-dap-python`), add to
   `dependencies` in `plugins/debug.lua` (see `langs.each` loop).
3. Configuration logic goes in `plugins/debug.lua` config function.
4. Run `./bin/lang/<language>.sh` to install the adapter binary.

## Add a REPL

1. Add `repl` chain to profile in `langs.lua` (richest first).
2. If REPL needs special command resolution, add logic to `plugins/repl.lua`.
3. Iron keymaps in `keymaps/leader-r.lua` are gated by `langs.repl()`.

## Design Principles Checklist

Before adding anything, verify:

- [ ] Does it derive from `langs.lua`? (No duplicate tool lists)
- [ ] Are user mappings in `config/keymaps/`? (Not in plugin spec)
- [ ] Is it lazy-loaded unless correctness requires eager?
- [ ] Does it follow the existing code style? (No comments on obvious syntax)
- [ ] Is there a test for new behavior? (Add to `tests/`)