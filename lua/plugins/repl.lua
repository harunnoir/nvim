--[[
The REPL: iron.nvim, which runs a real interpreter in a terminal buffer next to
your code and sends regions of that code to it.

The interesting part is `python_repl_command`. A REPL that cannot import the
thing you just wrote is worse than no REPL, so the command is chosen to match
your environment:

  1. the activated virtualenv, if there is one
  2. the project's own `.venv`
  3. `uv run`, project-aware, for a uv project
  4. the global fallback chain from `config/langs.lua`

Within each of those it prefers the richest interface available
(ptipython, then ipython, then ptpython, then plain python) so imports resolve
the same way your code does.
]]
local icons = require('config.icons')
local langs = require('config.langs')

---The path to `command` inside an environment's `bin/`, if it is there.
local function executable_in(directory, command)
    if not directory or directory == '' then
        return
    end
    local path = directory .. '/bin/' .. command
    return vim.fn.executable(path) == 1 and path or nil
end

---The richest REPL interface installed in an environment.
---Plain `python` is skipped here on purpose: it is the last resort, not a
---choice between interfaces.
local function preferred_repl(directory)
    for _, command in ipairs(langs.repl() or {}) do
        if command ~= 'python' and command ~= 'python3' then
            local path = executable_in(directory, command)
            if path then
                return { path }
            end
        end
    end
end

---A bare interpreter from an environment, for when no richer one is installed.
local function environment_python(directory)
    return executable_in(directory, 'python') or executable_in(directory, 'python3')
end

---`uv run`, with the REPL tools added on top without changing the project's
---declared dependencies. `--active` uses the environment you activated;
---`--project` uses the project's own.
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

---Wrap a single command path in the list iron expects.
---Returns nil for nil, so `a or b or wrap(maybe_nil)` still falls through.
local function wrap(command)
    return command and { command }
end

---Work out the REPL command for the buffer the REPL is opening from.
local function python_repl_command(meta)
    local root = vim.fs.root(meta and meta.current_bufnr or 0, { 'pyproject.toml', 'uv.lock', '.git' })
    local is_uv_project = root
        and (vim.uv.fs_stat(root .. '/pyproject.toml') or vim.uv.fs_stat(root .. '/uv.lock'))

    -- An explicitly activated environment wins, and uv can still add the
    -- richer interface to it without touching the project's dependencies.
    if vim.env.VIRTUAL_ENV then
        return preferred_repl(vim.env.VIRTUAL_ENV)
            or uv_repl(nil, true)
            or wrap(environment_python(vim.env.VIRTUAL_ENV))
    end

    -- Then the project's own environment, if it has one.
    local project_environment = root and root .. '/.venv' or nil
    if project_environment and vim.fn.isdirectory(project_environment) == 1 then
        return preferred_repl(project_environment)
            or (is_uv_project and uv_repl(root, false))
            or wrap(environment_python(project_environment))
    elseif is_uv_project then
        local command = uv_repl(root, false)
        if command then
            return command
        end
    end

    -- Finally whatever is on `PATH`, richest first.
    for _, command in ipairs(langs.repl() or {}) do
        if vim.fn.executable(command) == 1 then
            return { command }
        end
    end
    local python3 = vim.fn.exepath('python3')
    return { python3 ~= '' and python3 or 'python' }
end

local repl_enabled = langs.repl() ~= nil
local debugger = langs.debugger()

return {
    {
        'Vigemus/iron.nvim',
        ft = { 'python' },
        cmd = { 'IronRepl', 'IronRestart', 'IronFocus', 'IronHide' },
        enabled = repl_enabled,
        config = function()
            local iron = require('iron.core')
            local common = require('iron.fts.common')
            local view = require('iron.view')

            -- `Ctrl-\` inside the REPL hides it instead of opening a shell.
            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('enough_repl_keys', { clear = true }),
                desc = 'Map Ctrl-\\ inside the REPL',
                callback = function(args)
                    require('config.keymaps').repl(args.buf)
                end,
            })

            iron.setup({
                config = {
                    -- A throwaway REPL: a fresh process per buffer, no state
                    -- carried between files.
                    scratch_repl = true,
                    repl_definition = {
                        python = {
                            command = python_repl_command,
                            format = common.bracketed_paste_python,
                            -- `Ctrl-O` in Python splits a cell on `# %%`.
                            block_dividers = { '# %%', '#%%' },
                            -- Python 3.13 made its basic REPL stricter; without
                            -- this the terminal REPL fails to start.
                            env = { PYTHON_BASIC_REPL = '1' },
                        },
                    },
                    repl_filetype = function()
                        return 'iron'
                    end,
                    -- Let the debugger stop inside code sent from the REPL.
                    dap_integration = debugger ~= nil,
                    repl_open_cmd = view.split.botright('30%', {
                        winfixheight = false,
                        number = false,
                        relativenumber = false,
                        signcolumn = 'no',
                        winbar = ' ' .. icons.repl .. ' Python REPL ',
                    }),
                },
                -- Empty, because `config/keymaps.lua` owns every mapping.
                keymaps = {},
                highlight = { italic = false },
                -- Do not send the blank lines between functions.
                ignore_blank_lines = true,
            })
        end,
    },
}
