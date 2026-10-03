-- Editor options. Grouped by why they exist, not alphabetically.
local opt = vim.opt
local icons = require('config.icons')
local home = vim.uv.os_homedir() or vim.env.HOME

-- Mason installs language tools into Neovim's data directory, and the installers
-- put Python/C tools in the user-local bin. Prepend both only when they exist so
-- a tool installed after Neovim started is still found on the next launch.
for _, path in ipairs({
    vim.fn.stdpath('data') .. '/mason/bin',
    vim.env.XDG_BIN_HOME or (home .. '/.local/bin'),
    home .. '/.cargo/bin',
    home .. '/go/bin',
}) do
    if vim.fn.isdirectory(path) == 1 then
        vim.env.PATH = path .. ':' .. (vim.env.PATH or '')
    end
end

-- Files. `undofile` plus no backups means history survives without litter.
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.autowrite = true
opt.updatetime = 250

-- `confirm` catches `:q` and `:bd` before they discard work.
opt.confirm = true
opt.hidden = true

-- `timeoutlen` is how long a mapping waits for a longer sequence. 400ms keeps
-- `<leader>x` responsive without feeling twitchy on slow terminals.
opt.timeoutlen = 400
opt.ttimeoutlen = 20

-- Search. `hlsearch` stays off because highlighting every match is noise once
-- you are already moving through them with `]d` / `]c`.
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false
if vim.fn.executable('rg') == 1 then
    opt.grepprg = 'rg --vimgrep --smart-case --hidden'
    opt.grepformat = '%f:%l:%c:%m'
end

-- Indentation. Per-filetype overrides live in `config/autocmds.lua`.
opt.expandtab = true
opt.smartindent = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

-- Interface.
opt.termguicolors = true
opt.laststatus = 3
opt.showmode = false
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = 'yes'
opt.scrolloff = 4
opt.sidescrolloff = 4

-- Splits open where the eye already is, and a new one keeps the layout balanced.
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = 'screen'

-- `wrap` is off by default because long lines are usually a bug. `linebreak`
-- still makes wrapped text break at word boundaries when you do enable it.
opt.wrap = false
opt.linebreak = true
opt.smoothscroll = true
opt.winborder = 'rounded'

-- `menuone,noselect,popup`: the first item is preselected but not inserted, so
-- typing keeps filtering instead of committing a completion by accident.
opt.completeopt = { 'menuone', 'noselect', 'popup' }
opt.pumheight = 12

-- Whitespace. Makes trailing spaces and tabs visible, which is most of what
-- "did I leave junk in here" actually means.
opt.list = true
opt.listchars = { tab = '› ', trail = '·', nbsp = '␣' }
opt.fillchars = {
    eob = ' ',
    fold = ' ',
    foldopen = icons.fold_open,
    foldclose = icons.fold_closed,
    foldsep = ' ',
}

-- Mouse. Needed to scroll the Snacks pickers and to drag split borders.
opt.mouse = 'a'
opt.mousescroll = 'ver:3,hor:6'

-- `unnamedplus` means a plain `yank` also reaches the system clipboard, so
-- `<leader>ay` / `<leader>ax` need no register handling of their own.
opt.clipboard = 'unnamedplus'

-- `Ic` silences the "search hit BOTTOM" message; the cursor lands on the match.
opt.shortmess:append('Ic')

-- Spell is per-buffer, not global: `config/autocmds.lua` turns it on for prose.
opt.spell = false

-- Neovide animation and scaling. Guarded because these globals do not exist in
-- a plain terminal.
if vim.g.neovide then
    vim.g.neovide_scale_factor = 1.0
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_cursor_animation_length = 0.06
    vim.g.neovide_scroll_animation_length = 0.10
    vim.g.neovide_position_animation_length = 0.08
end
