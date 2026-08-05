local M = {}

function M.setup()
    local path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

    if not vim.uv.fs_stat(path) then
        local output = vim.fn.system({
            'git',
            'clone',
            '--filter=blob:none',
            '--branch=stable',
            'https://github.com/folke/lazy.nvim.git',
            path,
        })
        if vim.v.shell_error ~= 0 then
            error('Failed to install lazy.nvim:\n' .. output)
        end
    end

    vim.opt.rtp:prepend(path)

    local modules = require('modules')
    require('lazy').setup({
        spec = modules.specs(),
        defaults = { lazy = true, version = false },
        install = { colorscheme = modules.ui and { 'limei' } or { 'habamax' } },
        checker = { enabled = false },
        change_detection = { notify = false },
        performance = {
            rtp = {
                -- Oil is the default file explorer, so netrw is unnecessary.
                disabled_plugins = { 'netrwPlugin' },
            },
        },
        ui = { border = 'rounded' },
    })
end

return M
