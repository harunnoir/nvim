local languages = require('config.languages')
local school42_enabled = languages.c.enabled or languages.cpp.enabled

local function current_file(command)
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' or vim.fn.executable(command) ~= 1 then
        vim.notify(command .. ' is unavailable', vim.log.levels.WARN)
        return nil
    end
    return file
end

local function format42()
    local file = current_file('c_formatter_42')
    if not file then
        return
    end

    vim.cmd.write()
    local result = vim.system({ 'c_formatter_42', file }, { text = true }):wait()
    if result.code ~= 0 then
        vim.notify(result.stderr ~= '' and result.stderr or '42 formatting failed', vim.log.levels.ERROR)
        return
    end
    vim.cmd.checktime()
    vim.notify('42 formatting complete')
end

local function norminette()
    local file = current_file('norminette')
    if not file then
        return
    end

    local result = vim.system({ 'norminette', file }, { text = true }):wait()
    local output = vim.trim((result.stdout or '') .. (result.stderr or ''))
    local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
    vim.notify(output ~= '' and output or 'Norminette finished', level)
end

return {
    {
        'Diogo-ss/42-header.nvim',
        enabled = school42_enabled,
        cmd = { 'Stdheader', 'Format42', 'Check42' },
        opts = {
            default_map = false,
            auto_update = true,
            user = "abait-el",
            mail = "abait-el@student.1337.ma"
        },
        config = function(_, opts)
            require('42header').setup(opts)
            vim.api.nvim_create_user_command('Format42', format42, { desc = 'Format current file to 42 norm' })
            vim.api.nvim_create_user_command('Check42', norminette, { desc = 'Run Norminette on current file' })
        end,
    },
    {
        'hardyrafael17/norminette42.nvim',
        enabled = school42_enabled,
        ft = { 'c', 'cpp' },
        opts = {
            -- Keep Norminette manual so learning mode and ordinary saves stay quiet.
            runOnSave = false,
            maxErrorsToShow = 5,
            active = vim.fn.executable('norminette') == 1,
        },
        config = function(_, opts)
            require('norminette').setup(opts)
        end,
    },
}
