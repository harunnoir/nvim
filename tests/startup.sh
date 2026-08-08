#!/usr/bin/env bash
set -Eeuo pipefail

# Catch Lua syntax errors first, then load the complete configuration when the
# installed plugin set is available.
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
NVIM=${NVIM:-nvim}

! grep -Rq "have_nerd_font" "$ROOT/init.lua" "$ROOT/lua"
grep -Fq "icons.setup({ style = 'glyph' })" "$ROOT/lua/modules/editing.lua"
grep -Fq "nerd_font_variant = 'mono'" "$ROOT/lua/modules/coding.lua"
grep -Fq "implementation = 'rust'" "$ROOT/lua/modules/coding.lua"
! grep -Fq "icons.label('whole'" "$ROOT/lua/config/keymaps.lua"
grep -Fq "toggle_on" "$ROOT/lua/config/icons.lua"
grep -Fq "'folke/flash.nvim'" "$ROOT/lua/modules/navigation.lua"
! grep -Fq "'folke/flash.nvim'" "$ROOT/lua/modules/editing.lua"
! grep -Fq "<leader>ci" "$ROOT/lua/config/keymaps.lua"
grep -Fq "yaml = {" "$ROOT/lua/config/languages.lua"
grep -Fq "version = '*'" "$ROOT/lua/modules/navigation.lua"
! grep -Rq "icons.label" "$ROOT/lua"
! grep -Fq "prompt = icons.search" "$ROOT/lua/modules/navigation.lua"
! grep -Fq "scroll = { enabled" "$ROOT/lua/modules/ui.lua"

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
    XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$app" "$NVIM" --headless -i NONE -n \
        --cmd "lua vim.g.enough_languages={python=false,c=false,cpp=false}" \
        "+lua assert(vim.fn.maparg('<leader>rt', 'n') == '', 'REPL mappings ignored the Python switch')" \
        "+lua assert(vim.fn.maparg('<leader>dc', 'n') == '', 'debug mappings ignored language debuggers')" \
        "+lua assert(vim.fn.maparg('<leader>4h', 'n') == '', '42 mappings ignored C/C++ switches')" \
        +qa
    XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$app" "$NVIM" --headless -i NONE -n \
        --cmd "lua vim.g.enough_modules={ui=false}" \
        "+lua assert(vim.fn.maparg('<leader>wm', 'n') == '', 'maximize mapping ignored the UI switch')" \
        +qa
    printf 'startup test passed\n'
else
    printf 'Lua syntax passed; full startup skipped until plugins are installed\n'
fi
