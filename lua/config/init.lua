--[[
Startup order:

  1. options      → editor options (first)
  2. autocmds     → automatic behavior (filetype options, etc.)
  3. modes        → assistance toggles, learning/minimal, diagnostics (needed by first file)
  4. lazy         → plugin installation & setup
  5. lsp          → LSP servers (attach to existing buffers)
  6. keymaps      → user-facing mappings (last, wins conflicts)
]]
if vim.fn.has('nvim-0.12') ~= 1 then
    error('nvim requires Neovim 0.12 or newer')
end

local root = vim.fn.stdpath('config')

require('config.options')
require('config.autocmds')
require('config.modes').setup()
require('config.lazy').setup()
require('config.lsp').setup()
require('config.keymaps').setup()

-- Commands for working on the config itself. Editing `lua/config/langs.lua` is
-- the only edit that adds a language, so it is the one that gets a command.
local function edit(path)
    vim.cmd.edit(vim.fn.fnameescape(root .. '/' .. path))
end

vim.api.nvim_create_user_command('Config', function()
    edit('lua/config/langs.lua')
end, { desc = 'Edit the nvim language switches' })

vim.api.nvim_create_user_command('ConfigManual', function()
    edit('docs/manual.md')
end, { desc = 'Open the nvim manual' })

vim.api.nvim_create_user_command('ConfigHealth', function()
    -- `config/health.lua` is Neovim's health module for this name, and it
    -- derives every tool it reports from `config/langs.lua`.
    vim.cmd('checkhealth config')
end, { desc = 'Check the nvim configuration' })
