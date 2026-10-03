# nvim maintenance notes

- Keep root `init.lua` limited to leaders and `require('config')`.
- A feature exists because a line says so. There is no plugin enable/disable
  list, and there must not be one.
- Keep plugin setup in the file under `lua/plugins/` that owns the feature area.
  Every file there is a Lazy spec and is picked up automatically; add a file only
  when it owns a clear feature area.
- Keep language tools in `lua/config/langs.lua` and consume them instead of
  duplicating them. Anything derived from a profile (servers, formatters,
  linters, adapters, keymaps, health checks) is a bug if it is written twice.
- Keep every user-facing mapping in `lua/config/keymaps.lua`, including the ones
  a plugin would otherwise install for itself. Buffer-local mappings are
  installed from there by the plugin that owns the buffer.
- Reuse existing commands before installing anything.
- Keep `bin/install.sh` limited to the editor and plugin runtime requirements;
  language scripts are explicit and one per enabled language.
- Never call `sudo` or a distro package manager from the installer.
- Comment reasons and non-obvious constraints, not self-explanatory syntax.
- Treat performance as a constraint: defer optional features, keep required
  startup plugins stable, and measure before adding complex lazy-loading.
- Assume a Nerd Font; keep icons semantic, leave Mini Clue plain, and use Snacks
  defaults instead of a custom decoration layer.
- Run `make check` before publishing an archive.
- Split maximization uses `declancm/maximize.nvim`; keep its public mapping in
  `config/keymaps.lua` and its `MAX` state in Slimline.
- Keep Flash in the navigation file; Mini Surround and Tree-sitter text objects
  stay in editing.
- Gate REPL, debugger, and 42 mappings by the enabled language capabilities they
  require, so a disabled language removes its mappings instead of breaking them.
- Prefer uv for Python-native command-line tools so Python support does not pull
  in npm.
- Inside the Iron REPL, `Ctrl-\` hides the REPL; elsewhere it toggles the last
  Snacks terminal.
- Keep Blink on tagged releases, require the Rust matcher, and compile only when
  the prebuilt download fails.
- Blink, Snacks, Tree-sitter, Mason, Noice, and the statusline stay eager; when
  you add a plugin, decide which of those reasons applies to it, or make it lazy.
