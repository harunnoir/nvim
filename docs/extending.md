# Extending

## Add a plugin

1. Put its Lazy spec in the file in `lua/plugins/` that owns the area. A new
   file is picked up automatically; there is no list to register it in.
2. Put its user-facing mappings in the matching section of
   `lua/config/keymaps.lua`. If the plugin would install its own, set `keys =
   false` and map it here instead.
3. If it needs an external command, add it to `bin/install.sh` when it is needed
   by the editor itself, or to `bin/lang/<language>.sh` when it belongs to one
   language. Never use `sudo` or a distro package manager.

## Add a language

Two edits, and the rest follows:

1. Add a profile to `M.profiles` and a line to `M.enabled` in
   `lua/config/langs.lua`. The file contains a complete worked example.
2. Add `bin/lang/<language>.sh`.

That is the whole job. The profile decides which server `config/lsp.lua` starts,
which formatters conform runs, which linters run, which debugger adapter loads,
which REPL chain `plugins/repl.lua` prefers, whether the 42-school mappings
appear, and what `:ConfigHealth` reports. If you find yourself editing one of
those files to add a language, the profile is missing a field.

A profile may declare:

```lua
go = {
    filetype = { 'go', 'gomod' },
    lsp = 'gopls',                              -- a key in config/lsp.lua
    linters = { 'revive' },
    formatters = { 'gofumpt', 'goimports' },
    debugger = { name = 'delve', command = 'dlv' },
    repl = { 'go-repl' },                       -- first available wins
    norm = true,                               -- 42 norm applies to this
}
```

Keep every field factual: each one should be consumed somewhere. A field nothing
reads is a field to delete.

## Test a language for one session

```sh
nvim --cmd "lua vim.g.enough_languages={go=true,python=false}"
```

Overrides must name a language that has a profile, and must be booleans; anything
else is an error rather than a silent no-op.
