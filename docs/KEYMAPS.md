# Keymap Reference

This document is generated from the keymap modules in `lua/config/keymaps/`.

## Design Principles

1. **All user-facing mappings in one place** — `config/keymaps/`, including ones
   plugins would install.
2. **Buffer-local mappings installed by owner** — LSP, gitsigns, REPL from
   `keymaps/buffer.lua`, called in plugin `on_attach`.
3. **Descriptions mandatory** — Every mapping has a `desc` for Mini Clue and
   `:KeymapManual`.
4. **Groups by `<leader>` prefix** — One module per prefix, loaded by `init.lua`.
5. **Language-gated** — Debug, REPL, 42 mappings only exist when the relevant
   language is enabled.

## Module Structure

```
config/keymaps/
├── init.lua          → registry, manual, clues
├── general.lua       → non-leader mappings
├── leader-a.lua      → whole buffer
├── leader-b.lua      → buffers
├── leader-c.lua      → code
├── leader-d.lua      → debug
├── leader-f.lua      → find/files
├── leader-g.lua      → git
├── leader-i.lua      → AI (99)
├── leader-m.lua      → modes (minimal/learning)
├── leader-p.lua      → projects/tasks/sessions
├── leader-q.lua      → problems/lists
├── leader-r.lua      → REPL
├── leader-t.lua      → toggles
├── leader-w.lua      → windows
├── leader-x.lua      → terminal
├── leader-4.lua      → 42-school
└── buffer.lua        → buffer-local (LSP, gitsigns, REPL)
```

## Adding a Mapping

1. Find the right module by prefix (or `general.lua` for no prefix).
2. Add: `map(mode, lhs, rhs, opts('Description'))`
3. If new `<leader>` group: add to `M.clues()` in `init.lua`.

## Special Mappings

### Operator-Pending Mappings

These work with text objects and motions:
- `gc` / `gb` — comment operator (Comment.nvim)
- `ys` / `ds` / `cs` — surround operator (Mini Surround)
- `r` — Flash remote operator
- `]e` / `[e` — move line/selection

### Remapped Keys

| Original | Remapped To | Reason |
|----------|-------------|--------|
| `s` | Flash jump | `s` is more accessible than default Flash keys |
| `S` | Flash treesitter | Shift for larger scope |
| Mini Surround `s` | `ys`/`ds`/`cs` | Avoid conflict with Flash |

### Terminal Mode

- `<Esc><Esc>` → `<C-\><C-n>` (leave terminal mode)
- `<C-h/j/k/l>` → focus window (prefix with `<C-\><C-n>`)
- `<A-h/j/k/l>` → resize window

## Mini Clue Groups

Shown while holding `<leader>`. Defined in `keymaps/init.lua:M.clues()`:

| Prefix | Group | Condition |
|--------|-------|-----------|
| `a` | whole buffer | always |
| `b` | buffers | always |
| `c` | code | always |
| `d` | debug | debugger enabled |
| `f` | find/files | always |
| `g` | git | always |
| `i` | AI | always |
| `m` | modes | always |
| `p` | project/tasks | always |
| `q` | problems/lists | always |
| `r` | REPL | REPL enabled |
| `t` | toggles | always |
| `u` | undo | always |
| `w` | windows | always |
| `x` | terminal | always |
| `4` | 42 school | norm enabled |
| `i9` | 99 | always |

## Keymap Manual

`:KeymapManual` or `<leader>?` opens a Snacks picker with all active mappings.
- Read-only, on-demand
- Filterable, searchable
- Shows `desc` from each mapping
- Does not execute or modify mappings

## Testing

`tests/startup.lua` verifies:
- All expected mappings exist
- Buffer-local mappings install correctly
- Comment operators work
- Language-gated mappings respect switches