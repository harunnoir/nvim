# Extending

## Add a plugin

1. Put its Lazy specification in the closest existing module.
2. Put user-facing mappings in the matching section of `config/keymaps.lua`.
3. Add external commands to the installer only when the plugin genuinely needs them.

Create a new module only when the feature does not fit an existing obvious area.

## Add a language

1. Add its profile to `config/languages.lua`.
2. Add filetype mapping only where the shared code cannot infer it.
3. Add a small executable `bin/lang/<language>.sh` installer.
4. Add special LSP, debugger, or REPL setup only when the shared path is insufficient.

A language profile may describe:

```lua
{
  enabled = true,
  lsp = { 'type-checker', 'linter-with-an-LSP-server' },
  formatters = { 'formatter-name' },
  debugger = 'adapter-name',
  repl = { 'preferred-command', 'fallback-command' },
}
```

Keep the table factual: every field should be consumed by the configuration. Language installers remain explicit and separate from the core installer.
