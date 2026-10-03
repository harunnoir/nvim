#!/usr/bin/env bash
set -Eeuo pipefail

# Catch Lua syntax errors first, assert the few facts that are easy to break by
# moving a plugin between files, then load the whole configuration for real.
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
NVIM=${NVIM:-nvim}

# The Nerd Font is assumed, so no plugin may ask whether it is there, and the
# config owns the icons it uses rather than reading them out of devicons.
! grep -Rq "have_nerd_font" "$ROOT/init.lua" "$ROOT/lua"
! grep -Rq "icons.label" "$ROOT/lua"

grep -Fq "icons.setup({ style = 'glyph' })" "$ROOT/lua/plugins/editing.lua"
grep -Fq "nerd_font_variant = 'mono'" "$ROOT/lua/plugins/coding.lua"
grep -Fq "implementation = 'rust'" "$ROOT/lua/plugins/coding.lua"
grep -Fq "toggle_on" "$ROOT/lua/config/icons.lua"

# Each plugin lives in the area it belongs to, and in only that area.
grep -Fq "'folke/flash.nvim'" "$ROOT/lua/plugins/navigation.lua"
! grep -Fq "'folke/flash.nvim'" "$ROOT/lua/plugins/editing.lua"
grep -Fq "'numToStr/Comment.nvim'" "$ROOT/lua/plugins/editing.lua"
grep -Fq "mini.move" "$ROOT/lua/plugins/editing.lua"
grep -Fq "mini.splitjoin" "$ROOT/lua/plugins/editing.lua"
grep -Fq "'j-hui/fidget.nvim'" "$ROOT/lua/plugins/coding.lua"
grep -Fq "'theHamsta/nvim-dap-virtual-text'" "$ROOT/lua/plugins/debug.lua"
grep -Fq "'sindrets/diffview.nvim'" "$ROOT/lua/plugins/git.lua"
grep -Fq "version = '*'" "$ROOT/lua/plugins/navigation.lua"

# The old module switch system must be gone, not merely unused.
! grep -RqF "require('modules')" "$ROOT/lua"
! grep -RqF "scroll = { enabled" "$ROOT/lua"

# Languages are the only switch, and they are switched on in lua/config/langs.lua.
grep -Fq "python = true" "$ROOT/lua/config/langs.lua"
grep -Fq "c = true" "$ROOT/lua/config/langs.lua"
grep -Fq "cpp = true" "$ROOT/lua/config/langs.lua"
! grep -RqF "languages" "$ROOT/lua"

command -v "$NVIM" >/dev/null 2>&1 || {
    printf 'nvim is unavailable; startup test skipped\n'
    exit 0
}

ROOT="$ROOT" "$NVIM" --headless -u NONE -i NONE -n \
    "+lua for _,p in ipairs(vim.fn.glob(vim.env.ROOT .. '/**/*.lua', false, true)) do local f,e=loadfile(p); assert(f,e) end" \
    +qa

app=$(basename "$ROOT")
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
plugins=(lazy.nvim snacks.nvim blink.cmp nvim-treesitter iron.nvim todo-comments.nvim maximize.nvim)
ready=1
for plugin in "${plugins[@]}"; do
    [[ -d "$data_home/$app/lazy/$plugin" ]] || ready=0
done

if [[ $ready == 1 ]]; then
    XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$app" "$NVIM" --headless -i NONE -n \
        "+lua dofile(vim.fn.stdpath('config') .. '/tests/startup.lua')" \
        +qa

    # The single language switch has to actually gate the features that depend
    # on it, or a language you switched off is still wired in.
    XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$app" "$NVIM" --headless -i NONE -n \
        --cmd "lua vim.g.enough_languages={python=false,c=false,cpp=false}" \
        "+lua assert(vim.fn.maparg('<leader>rt', 'n') == '', 'REPL mappings ignored the Python switch')" \
        "+lua assert(vim.fn.maparg('<leader>dc', 'n') == '', 'debug mappings ignored language debuggers')" \
        "+lua assert(vim.fn.maparg('<leader>4h', 'n') == '', '42 mappings ignored C/C++ switches')" \
        +qa
    printf 'startup test passed\n'
else
    printf 'Lua syntax passed; full startup skipped until plugins are installed\n'
fi
