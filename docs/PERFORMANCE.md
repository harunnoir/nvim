# Performance Guide

## Startup Time

Target: **< 50ms** on modern hardware.

Measure:
```vim
:Lazy profile
```

Or from shell:
```sh
/usr/bin/time -f "%E real" nvim --headless +qa
```

## What Loads at Startup (and Why)

| Plugin | Event | Reason |
|--------|-------|--------|
| `blink.cmp` | `lazy=false` | LSP client capabilities must be sent when server is configured, not on first completion |
| `nvim-treesitter` | `lazy=false` | Official API expects parser to exist before first file opens |
| `snacks.nvim` | `lazy=false` | Replaces built-in notifications, terminal buffers, statusline spinner at startup |
| `slimline.nvim` | `lazy=false` | Statusline visible immediately; late appearance is worse than none |
| `mason.nvim` | `lazy=false`, priority=900 | `PATH` prepend must happen before other tools run |
| `noice.nvim` | `VeryLazy` | Command line UI can appear later |
| Everything else | Lazy / event-based | No correctness dependency on early load |

## Blink Rust Matcher

Blink requires its Rust fuzzy matcher for acceptable performance on large projects.

**Tagged releases (1.*):** Automatically download prebuilt `libblink_cmp_fuzzy` into
`stdpath('data')/lazy/blink.cmp/target/release/`.

**Fallback:** If download fails, `bin/install.sh` compiles with Cargo.

Verify:
```vim
:checkhealth blink.cmp
```

Look for:
```
blink.cmp
  ✓ Rust fuzzy matcher: /path/to/libblink_cmp_fuzzy.so
```

## Lazy-Loading Checklist

When adding a plugin, decide its load event:

1. **Does anything correct depend on its API at startup?**
   - LSP capabilities → eager
   - Replaces built-in (netrw, notifications) → eager
   - Statusline component → eager
   - Otherwise → lazy

2. **What triggers it?**
   - Filetype → `ft = 'python'`
   - Command → `cmd = 'CommandName'`
   - Keypress → `keys = { '<leader>x' }` (but prefer keymaps in `config/keymaps/`)
   - Event → `event = 'BufReadPost'`, `LspAttach`, etc.
   - Nothing specific → `event = 'VeryLazy'`

3. **Avoid `lazy = false` unless justified** — document the reason in the spec.

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Plugin loads early but only used on keypress | Slow startup, `:Lazy profile` shows high cost | Change to `keys` or `cmd` trigger |
| Multiple plugins do the same thing | Duplicate work, conflicts | Consolidate to one (e.g., Snacks for picker/terminal/git) |
| Tree-sitter parsers for unused languages | Slow `:TSUpdate`, memory | Only install parsers for enabled languages (`bin/install.sh` does this) |
| Blink Rust matcher not found | Completion lag, `:checkhealth blink.cmp` warns | Run `./bin/install.sh` to download/compile |

## Profiling Workflow

1. **Baseline:** `nvim --headless +Lazy\ profile +qa 2>&1 | head -30`
2. **Identify outliers:** Look for plugins with high `require` or `config` time
3. **Test change:** Modify load event, re-run profile
4. **Verify correctness:** Run `make test` — ensure no feature regression

### Benchmark Script

Run `./tests/benchmark.sh` for a quick startup time check (requires installed plugins):

```bash
#!/usr/bin/env bash
# Performance benchmark script
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
NVIM=${NVIM:-nvim}
APP_NAME=$(basename "$ROOT")

echo "=== Startup Time (5 runs) ==="
for i in {1..5}; do
    /usr/bin/time -f "%E real" \
        XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$APP_NAME" \
        "$NVIM" --headless +qa 2>&1 | grep -E '^[0-9:]'
done

echo ""
echo "=== Lazy Profile ==="
XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$APP_NAME" \
    "$NVIM" --headless "+Lazy profile" +qa 2>&1 | head -40
```

## Optimizing Treesitter

Only parsers for enabled languages are installed (`bin/install.sh` calls
`install_parsers` with the exact list from `langs.lua`). To add a language:

1. Add parser name to `install_parsers` call in the language's `bin/lang/*.sh`
2. The parser loads on-demand when a file of that type opens

## Memory

- `bigfile` (Snacks) handles large files automatically
- `quickfile` (Snacks) speeds up startup for small files
- `vim-illuminate` has `large_file_cutoff = 2000` and `min_count_to_highlight = 2`
- `nvim-dap-virtual-text` only activates during debug sessions

## Network

- No automatic plugin update checks (`checker = { enabled = false }`)
- No config change notifications (`change_detection = { notify = false }`)
- Mason registry refresh only on explicit `Lazy! sync` or language install

## Benchmarks

Run the test suite to verify performance hasn't regressed:
```sh
make check
```

This runs:
- Lua syntax check (stylua)
- Shell script syntax check (bash -n, shellcheck if available)
- Installer structure test
- Full startup test (loads config, verifies keymaps, toggles, learning mode)