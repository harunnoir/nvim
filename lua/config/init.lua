if vim.fn.has('nvim-0.12') ~= 1 then
    error('enough-nvim requires Neovim 0.12 or newer')
end

local modules = require('modules')
local root = vim.fn.stdpath('config')

require('config.options')
require('config.autocmds')
require('config.toggles').setup()
require('config.lazy').setup()
require('config.keymap_manual').setup()
require('config.keymaps').setup()

if modules.coding then
    require('config.lsp').setup()
end

local function edit(path)
    vim.cmd.edit(vim.fn.fnameescape(root .. '/' .. path))
end

vim.api.nvim_create_user_command('Config', function()
    edit('lua/modules/init.lua')
end, { desc = 'Edit enough-nvim module switches' })

vim.api.nvim_create_user_command('ConfigLanguages', function()
    edit('lua/config/languages.lua')
end, { desc = 'Edit enough-nvim language tools' })

vim.api.nvim_create_user_command('ConfigManual', function()
    edit('docs/manual.md')
end, { desc = 'Open the enough-nvim manual' })

vim.api.nvim_create_user_command('ConfigHealth', function()
    local checks = { 'config' }
    if modules.ui or modules.navigation or modules.terminal or modules.git then
        checks[#checks + 1] = 'snacks'
    end
    if modules.coding or modules.debug then
        checks[#checks + 1] = 'mason'
    end
    if modules.coding then
        checks[#checks + 1] = 'blink.cmp'
        checks[#checks + 1] = 'vim.lsp'
    end
    if modules.editing then
        checks[#checks + 1] = 'nvim-treesitter'
    end
    vim.cmd('checkhealth ' .. table.concat(checks, ' '))
end, { desc = 'Check enabled enough-nvim features' })
