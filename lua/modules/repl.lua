local languages = require('config.languages')
local modules = require('modules')
local python = languages.python
local icons = require('config.icons')

local function executable_in(directory, command)
    if not directory or directory == '' then
        return
    end
    local path = directory .. '/bin/' .. command
    return vim.fn.executable(path) == 1 and path or nil
end

local function preferred_repl(directory)
    for _, command in ipairs(python.repl or {}) do
        if command ~= 'python' and command ~= 'python3' then
            local path = executable_in(directory, command)
            if path then
                return { path }
            end
        end
    end
end

local function environment_python(directory)
    return executable_in(directory, 'python') or executable_in(directory, 'python3')
end

local function uv_repl(root, active)
    if vim.fn.executable('uv') ~= 1 then
        return
    end
    local command = { 'uv', 'run' }
    if active then
        command[#command + 1] = '--active'
    elseif root then
        command[#command + 1] = '--project'
        command[#command + 1] = root
    end
    vim.list_extend(command, { '--with', 'ptpython', '--with', 'ipython', 'ptipython' })
    return command
end

local function python_repl_command(meta)
    local root = vim.fs.root(meta and meta.current_bufnr or 0, { 'pyproject.toml', 'uv.lock', '.git' })
    local is_uv_project = root
        and (vim.uv.fs_stat(root .. '/pyproject.toml') or vim.uv.fs_stat(root .. '/uv.lock'))

    -- An explicitly activated environment wins. uv can inject the richer
    -- interface without changing the project's declared dependencies.
    if vim.env.VIRTUAL_ENV then
        local rich = preferred_repl(vim.env.VIRTUAL_ENV)
        if rich then
            return rich
        end
        local command = uv_repl(nil, true)
        if command then
            return command
        end
        local plain = environment_python(vim.env.VIRTUAL_ENV)
        if plain then
            return { plain }
        end
    end

    local project_environment = root and root .. '/.venv' or nil
    if project_environment and vim.fn.isdirectory(project_environment) == 1 then
        local rich = preferred_repl(project_environment)
        if rich then
            return rich
        end
        if is_uv_project then
            local command = uv_repl(root, false)
            if command then
                return command
            end
        end
        local plain = environment_python(project_environment)
        if plain then
            return { plain }
        end
    elseif is_uv_project then
        local command = uv_repl(root, false)
        if command then
            return command
        end
    end

    for _, command in ipairs(python.repl or {}) do
        if vim.fn.executable(command) == 1 then
            return { command }
        end
    end
    local python3 = vim.fn.exepath('python3')
    return { python3 ~= '' and python3 or 'python' }
end

return {
    {
        'Vigemus/iron.nvim',
        ft = { 'python' },
        cmd = { 'IronRepl', 'IronRestart', 'IronFocus', 'IronHide' },
        enabled = python.enabled and type(python.repl) == 'table' and #python.repl > 0,
        config = function()
            local iron = require('iron.core')
            local common = require('iron.fts.common')
            local view = require('iron.view')

            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('enough_repl_keys', { clear = true }),
                pattern = 'iron',
                callback = function(args)
                    vim.keymap.set({ 'n', 't' }, '<C-\\>', '<cmd>IronHide<cr>', {
                        buffer = args.buf,
                        silent = true,
                        desc = 'Hide Python REPL',
                    })
                end,
            })

            iron.setup({
                config = {
                    scratch_repl = true,
                    repl_definition = {
                        python = {
                            command = python_repl_command,
                            format = common.bracketed_paste_python,
                            block_dividers = { '# %%', '#%%' },
                            -- Python 3.13+ requires this for its basic terminal REPL.
                            env = { PYTHON_BASIC_REPL = '1' },
                        },
                    },
                    repl_filetype = function()
                        return 'iron'
                    end,
                    dap_integration = modules.debug and python.debugger ~= nil,
                    repl_open_cmd = view.split.botright('30%', {
                        winfixheight = false,
                        number = false,
                        relativenumber = false,
                        signcolumn = 'no',
                        winbar = ' ' .. icons.repl .. ' Python REPL ',
                    }),
                },
                keymaps = {},
                highlight = { italic = false },
                ignore_blank_lines = true,
            })
        end,
    },
}
