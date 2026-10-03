--[[
Debugging: nvim-dap plus the adapters for the languages you enabled.

Which adapters exist is decided by `config/langs.lua`, so enabling a language
with a `debugger` is what brings its adapter in. Each adapter is also checked at
runtime: a missing binary falls back to something simpler or is skipped, rather
than failing when you press `<leader>dc`.
]]
local icons = require('config.icons')
local langs = require('config.langs')

local enabled = langs.uses('debugger')

---The debugger of a language, but only when that language is switched on.
---`langs.profile` already returns nil for a disabled language, so the point of
---the helper is to keep one `and` chain from having to repeat it.
local function enabled_debugger(language)
    local profile = langs.profile(language)
    return profile and profile.debugger and profile.debugger.name
end

---Read a script's shebang and resolve it to a runnable interpreter.
---debugpy ships as a console script, so its own shebang is the most reliable
---answer to "which Python should debug this" -- more reliable than guessing.
local function interpreter_from_script(script)
    local first = vim.fn.readfile(script, '', 1)[1] or ''
    local interpreter = first:match('^#!%s*(.+)$')
    if not interpreter then
        return
    end

    -- `#!/usr/bin/env python3` names a command to look up, not a path.
    local env_command = interpreter:match('^/usr/bin/env%s+([^%s]+)$')
    if env_command then
        local path = vim.fn.exepath(env_command)
        return path ~= '' and path or nil
    end
    return vim.fn.executable(interpreter) == 1 and interpreter or nil
end

---The interpreter to debug with: the activated environment, then the project's
---own `.venv`, then whatever Python is on `PATH`. Same order as the REPL.
local function project_python()
    if vim.env.VIRTUAL_ENV then
        local active = vim.env.VIRTUAL_ENV .. '/bin/python'
        if vim.fn.executable(active) == 1 then
            return active
        end
    end

    local root = vim.fs.root(0, { 'pyproject.toml', 'uv.lock', '.git' })
    if root then
        local local_python = root .. '/.venv/bin/python'
        if vim.fn.executable(local_python) == 1 then
            return local_python
        end
    end

    local python3 = vim.fn.exepath('python3')
    return python3 ~= '' and python3 or 'python'
end

---Adapters to install alongside nvim-dap, based on the enabled languages.
local dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
    'mason-org/mason.nvim',
}

langs.each(function(profile, name)
    if profile.debugger and profile.debugger.name == 'debugpy' then
        dependencies[#dependencies + 1] = 'mfussenegger/nvim-dap-python'
    elseif name == 'delve' then
        dependencies[#dependencies + 1] = 'leoluz/nvim-dap-go'
    end
end)

return {
    {
        'mfussenegger/nvim-dap',
        enabled = enabled,
        dependencies = dependencies,
        config = function()
            local dap = require('dap')
            local dapui = require('dapui')

            dapui.setup({ floating = { border = 'rounded' } })

            -- Inline values for the variable under the cursor while stepping.
            -- This replaces hand-written `print` debugging for most sessions.
            require('nvim-dap-virtual-text').setup()

            -- Open the UI when a session starts, close it when one ends, so
            -- `dapui` is never left open over a finished session.
            dap.listeners.after.event_initialized['dapui'] = dapui.open
            dap.listeners.before.event_terminated['dapui'] = dapui.close
            dap.listeners.before.event_exited['dapui'] = dapui.close

            vim.fn.sign_define('DapBreakpoint', { text = icons.breakpoint, texthl = 'DiagnosticSignError' })
            vim.fn.sign_define('DapStopped', { text = icons.stopped, texthl = 'DiagnosticSignWarn', linehl = 'Visual' })

            -- ---- Python ----------------------------------------------------
            if enabled_debugger('python') == 'debugpy' then
                local adapter = vim.fn.exepath('debugpy-adapter')
                if adapter == '' then
                    -- debugpy is not installed; the health check says so.
                else
                    local python = interpreter_from_script(adapter)
                    if python then
                        -- The Python adapter is the good one: it understands
                        -- pytest and frames properly.
                        require('dap-python').setup(python)
                        require('dap-python').test_runner = 'pytest'
                        -- Overwrite the interpreter it detected so debugging uses
                        -- the same environment as the REPL.
                        for _, configuration in ipairs(dap.configurations.python or {}) do
                            configuration.pythonPath = project_python
                        end
                    else
                        -- No readable shebang: fall back to a plain executable
                        -- adapter and a single "debug this file" configuration.
                        dap.adapters.python = { type = 'executable', command = adapter }
                        dap.configurations.python = {
                            {
                                type = 'python',
                                request = 'launch',
                                name = 'Launch current file',
                                program = '${file}',
                                cwd = '${workspaceFolder}',
                                pythonPath = project_python,
                            },
                        }
                    end
                end
            end

            -- ---- Go --------------------------------------------------------
            if enabled_debugger('go') == 'delve' and vim.fn.executable('dlv') == 1 then
                require('dap-go').setup({ delve = { path = vim.fn.exepath('dlv') } })
            end

            -- ---- C, C++, Rust: one LLDB-based adapter ----------------------
            local native = {}
            for _, language in ipairs({ 'c', 'cpp', 'rust' }) do
                if enabled_debugger(language) then
                    native[#native + 1] = language
                end
            end

            if #native > 0 then
                local codelldb = vim.fn.exepath('codelldb')
                local lldb_dap = vim.fn.exepath('lldb-dap')
                local adapter_type

                if codelldb ~= '' then
                    adapter_type = 'codelldb'
                    -- `--port` lets codelldb pick a free port per session.
                    dap.adapters.codelldb = {
                        type = 'server',
                        port = '${port}',
                        executable = { command = codelldb, args = { '--port', '${port}' } },
                    }
                elseif lldb_dap ~= '' then
                    adapter_type = 'lldb'
                    dap.adapters.lldb = { type = 'executable', command = lldb_dap, name = 'lldb' }
                end

                if adapter_type then
                    -- Ask which binary to run. Debugging C from a source file is
                    -- normal, so there is no sensible default worth guessing.
                    local launch = {
                        name = 'Launch executable',
                        type = adapter_type,
                        request = 'launch',
                        program = function()
                            return vim.fn.input('Executable: ', vim.fn.getcwd() .. '/', 'file')
                        end,
                        cwd = '${workspaceFolder}',
                        stopOnEntry = false,
                        args = {},
                    }
                    for _, language in ipairs(native) do
                        dap.configurations[language] = { vim.deepcopy(launch) }
                    end
                end
            end
        end,
    },
}
