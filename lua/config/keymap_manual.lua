-- On-demand keymap reference.
-- It reads active mappings at runtime and never creates, changes, or executes them.
local M = {}
function M.open()
    if Snacks and Snacks.picker and Snacks.picker.keymaps then
        Snacks.picker.keymaps({
            title = 'Keymap Manual',
            plugs = false,
            confirm = 'close',
        })
        return
    end

    vim.notify('Keymap manual requires the Snacks UI module', vim.log.levels.WARN)
end

function M.setup()
    vim.api.nvim_create_user_command('KeymapManual', M.open, {
        desc = 'Search active Neovim keymaps',
    })
end

return M
