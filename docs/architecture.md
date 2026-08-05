# Architecture

The configuration has two simple layers:

```text
init.lua
  ├── lua/config/   shared editor behavior
  └── lua/modules/  one file per obvious feature area
```

## Shared configuration

`lua/config/` contains editor-wide behavior:

```text
init.lua       startup order and config commands
options.lua    editor options
autocmds.lua   shared automatic behavior
keymaps.lua    complete public keyboard interface
keymap_manual.lua on-demand searchable mapping reference
lazy.lua       plugin manager bootstrap
languages.lua enabled languages and their tools
lsp.lua        shared native LSP behavior
toggles.lua    assistance toggles and learning mode
health.lua     configuration health report
icons.lua      shared semantic Nerd Font glyphs
```

## Feature modules

`lua/modules/init.lua` enables modules and loads them in a predictable order.
Each remaining module owns one feature area:

```text
ui          colorscheme, statusline, notifications, window maximize
editing     pairs, surrounds, Tree-sitter, text objects
navigation  Flash, files, buffers, search, Oil, TODO comments, Trouble
coding      Mason, completion, formatting, LSP-facing tools
terminal    terminal creation and management
repl        interactive code execution
debug       DAP and language adapters
git         Gitsigns and LazyGit
project     projects, tasks, and sessions
school42    header, Norminette, c_formatter_42
```

## Rules

1. Keep responsibilities obvious from filenames.
2. Add files only when they remove real confusion or duplication.
3. Keep public mappings in `config/keymaps.lua`.
4. Keep language definitions in `config/languages.lua`.
5. Let disabled modules stay unloaded.
6. Prefer built-in Neovim behavior when it already solves the problem well.

## UI icons

`lua/config/icons.lua` keeps only state and tool glyphs used by diagnostics,
Slimline, terminals, TODO comments, and debugging. Snacks uses its defaults, while
Mini Clue keeps plain group names. `mini.icons` provides file and LSP-kind glyphs.

## Performance rules

1. Lazy-load a plugin only when its API does not need to exist during startup.
2. Keep Tree-sitter and Snacks startup-loaded because their supported setup requires it.
3. Prefer tagged prebuilt native components; compile only as a verified fallback.
4. Disable visual effects with continuous redraw cost unless they provide real utility.
5. Measure with `:Lazy profile` before adding complicated loading conditions.
