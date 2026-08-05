local opt = vim.opt
local icons = require('config.icons')
local home = vim.uv.os_homedir() or vim.env.HOME
local data = vim.fn.stdpath('data')

-- Prefer Neovim-managed and user-local commands without duplicating PATH.
local paths = {
    data .. '/mason/bin',
    vim.env.XDG_BIN_HOME or (home .. '/.local/bin'),
    home .. '/.cargo/bin',
    home .. '/go/bin',
}
local known = vim.split(vim.env.PATH or '', ':', { plain = true })
for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 1 and not vim.tbl_contains(known, path) then
        vim.env.PATH = path .. ':' .. (vim.env.PATH or '')
        table.insert(known, 1, path)
    end
end

-- Files and editing.
opt.autowrite = true
opt.confirm = true
opt.hidden = true
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.updatetime = 250
opt.timeoutlen = 400
opt.ttimeoutlen = 20

-- Search.
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = false
if vim.fn.executable('rg') == 1 then
    opt.grepprg = 'rg --vimgrep --smart-case --hidden'
    opt.grepformat = '%f:%l:%c:%m'
end

-- Indentation.
opt.expandtab = true
opt.smartindent = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

-- Interface.
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = 'yes'
opt.scrolloff = 4
opt.sidescrolloff = 4
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = 'screen'
opt.laststatus = 3
opt.showmode = false
opt.wrap = false
opt.linebreak = true
opt.smoothscroll = true
opt.winborder = 'rounded'
opt.pumheight = 12
opt.completeopt = { 'menuone', 'noselect', 'popup' }
opt.shortmess:append('Ic')
opt.list = true
opt.listchars = { tab = '› ', trail = '·', nbsp = '␣' }
opt.fillchars = {
    eob = ' ',
    fold = ' ',
    foldopen = icons.fold_open,
    foldclose = icons.fold_closed,
    foldsep = ' ',
}
opt.mouse = 'a'
opt.mousescroll = 'ver:3,hor:6'
opt.clipboard = 'unnamedplus'
opt.spell = false
opt.guifont = 'IosevkaTerm Nerd Font:h14'

if vim.g.neovide then
    vim.g.neovide_scale_factor = 1.0
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_cursor_animation_length = 0.06
    vim.g.neovide_scroll_animation_length = 0.10
    vim.g.neovide_position_animation_length = 0.08
end
