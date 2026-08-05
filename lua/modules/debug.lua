local icons = require('config.icons')
local languages = require('config.languages')
local debug_enabled = vim.iter(languages):any(function(_, profile)
    return type(profile) == 'table' and profile.enabled and profile.debugger ~= nil
end)
local dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'mason-org/mason.nvim',
}

if languages.python.enabled and languages.python.debugger == 'debugpy' then
    dependencies[#dependencies + 1] = 'mfussenegger/nvim-dap-python'
end
if languages.go.enabled and languages.go.debugger == 'delve' then
    dependencies[#dependencies + 1] = 'leoluz/nvim-dap-go'
end

local function interpreter_from_script(script)
    local first = vim.fn.readfile(script, '', 1)[1] or ''
    local interpreter = first:match('^#!%s*(.+)$')
    if not interpreter then
        return
    end

    local env_command = interpreter:match('^/usr/bin/env%s+([^%s]+)$')
    if env_command then
        local path = vim.fn.exepath(env_command)
        return path ~= '' and path or nil
    end
    return vim.fn.executable(interpreter) == 1 and interpreter or nil
end

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

return {
    {
        'mfussenegger/nvim-dap',
        enabled = debug_enabled,
        dependencies = dependencies,
        config = function()
            local dap = require('dap')
            local dapui = require('dapui')

            dapui.setup({ floating = { border = 'rounded' } })
            dap.listeners.after.event_initialized['dapui'] = dapui.open
            dap.listeners.before.event_terminated['dapui'] = dapui.close
            dap.listeners.before.event_exited['dapui'] = dapui.close

            vim.fn.sign_define('DapBreakpoint', { text = icons.breakpoint, texthl = 'DiagnosticSignError' })
            vim.fn.sign_define('DapStopped', { text = icons.stopped, texthl = 'DiagnosticSignWarn', linehl = 'Visual' })

            if languages.python.enabled and languages.python.debugger == 'debugpy' then
                local adapter = vim.fn.exepath('debugpy-adapter')
                local python = adapter ~= '' and interpreter_from_script(adapter) or nil
                if python then
                    require('dap-python').setup(python)
                    require('dap-python').test_runner = 'pytest'
                    for _, configuration in ipairs(dap.configurations.python or {}) do
                        configuration.pythonPath = project_python
                    end
                elseif adapter ~= '' then
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

            if languages.go.enabled and languages.go.debugger == 'delve' and vim.fn.executable('dlv') == 1 then
                require('dap-go').setup({ delve = { path = vim.fn.exepath('dlv') } })
            end

            local native_enabled = (languages.c.enabled and languages.c.debugger)
                or (languages.cpp.enabled and languages.cpp.debugger)
                or (languages.rust.enabled and languages.rust.debugger)

            if native_enabled then
                local codelldb = vim.fn.exepath('codelldb')
                local lldb_dap = vim.fn.exepath('lldb-dap')
                local adapter_type

                if codelldb ~= '' then
                    adapter_type = 'codelldb'
                    dap.adapters.codelldb = {
                        type = 'server',
                        port = '${port}',
                        executable = { command = codelldb, args = { '--port', '${port}' } },
                    }
                elseif lldb_dap ~= '' then
                    adapter_type = 'lldb'
                    dap.adapters.lldb = {
                        type = 'executable',
                        command = lldb_dap,
                        name = 'lldb',
                    }
                end

                if adapter_type then
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

                    if languages.c.enabled then
                        dap.configurations.c = { vim.deepcopy(launch) }
                    end
                    if languages.cpp.enabled then
                        dap.configurations.cpp = { vim.deepcopy(launch) }
                    end
                    if languages.rust.enabled then
                        dap.configurations.rust = { vim.deepcopy(launch) }
                    end
                end
            end
        end,
    },
}
