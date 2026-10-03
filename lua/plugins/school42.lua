--[[
42-school tools: header, formatting, and Norminette.

Present only when a language the 42 norm applies to is enabled, which is what
`langs.uses('norm')` answers. Everything here is external to Neovim -- the
header, the formatter, and the linter are 42-approved binaries -- so this file is
mostly about refusing to run them on a file they cannot help.
]]
local langs = require('config.langs')

local enabled = langs.uses('norm')

---The current file, or nil with an explanation.
---Both tools are external binaries, so a missing one is normal on a machine
---that has not run `bin/lang/c.sh` yet, and worth saying rather than failing.
local function current_file(command)
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then
        vim.notify('No file name yet', vim.log.levels.WARN)
        return nil
    end
    if vim.fn.executable(command) ~= 1 then
        vim.notify(command .. ' is not installed; see bin/lang/c.sh', vim.log.levels.WARN)
        return nil
    end
    return file
end

---Rewrite the current file with the 42 formatter, then reload it.
---The write is deliberate: the formatter only takes a path, so the file on disk
---has to be the version in the buffer.
local function format42()
    local file = current_file('c_formatter_42')
    if not file then
        return
    end

    vim.cmd.write()
    local result = vim.system({ 'c_formatter_42', file }, { text = true }):wait()
    if result.code ~= 0 then
        vim.notify(result.stderr ~= '' and vim.trim(result.stderr) or '42 formatting failed', vim.log.levels.ERROR)
        return
    end
    -- Pick the reformatted file up; nothing else reloads it for us.
    vim.cmd.checktime()
    vim.notify('42 formatting complete')
end

---Run Norminette on the current file and report what it says.
---Norminette reports style problems on stdout and failures on stderr, so both
---are shown, and a non-zero exit is not treated as a crash.
local function norminette()
    local file = current_file('norminette')
    if not file then
        return
    end

    local result = vim.system({ 'norminette', file }, { text = true }):wait()
    local output = vim.trim((result.stdout or '') .. (result.stderr or ''))
    vim.notify(
        output ~= '' and output or 'Norminette found nothing to complain about',
        result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
    )
end

return {
    {
        'Diogo-ss/42-header.nvim',
        enabled = enabled,
        cmd = { 'Stdheader', 'Format42', 'Check42' },
        opts = {
            -- Keys stay in `config/keymaps.lua`; the plugin's own defaults would
            -- duplicate them.
            default_map = false,
            -- The header follows the filename, so a renamed file is fixed up
            -- instead of keeping a header that no longer matches.
            auto_update = true,
            user = 'abait-el',
            mail = 'abait-el@student.1337.ma',
        },
        config = function(_, opts)
            require('42header').setup(opts)
            vim.api.nvim_create_user_command('Format42', format42, { desc = 'Format the current file to 42 norm' })
            vim.api.nvim_create_user_command('Check42', norminette, { desc = 'Run Norminette on the current file' })
        end,
    },
    {
        'hardyrafael17/norminette42.nvim',
        enabled = enabled,
        ft = { 'c', 'cpp' },
        opts = {
            -- Never on save. Norminette's output is the 42 norm stated as prose,
            -- and running it while you are mid-edit produces noise instead of
            -- feedback; `<leader>4n` asks for it.
            runOnSave = false,
            maxErrorsToShow = 5,
            -- Off until the binary is actually installed.
            active = vim.fn.executable('norminette') == 1,
        },
        config = function(_, opts)
            require('norminette').setup(opts)
        end,
    },
}
