-- Snacks already provides terminal windows; this module adds a small, named
-- terminal workflow without installing another terminal manager.
local api = vim.api
local icons = require('config.icons')
local next_terminal_id = 20
local last_terminal

local function root_dir()
    return vim.fs.root(0, { '.git', 'pyproject.toml', 'Cargo.toml', 'go.mod', 'Makefile' }) or vim.fn.getcwd()
end

local function file_dir()
    local file = api.nvim_buf_get_name(0)
    return file ~= '' and vim.fn.fnamemodify(file, ':p:h') or vim.fn.getcwd()
end

local function term_opts(position, count, cwd, name)
    local win = { position = position, border = 'rounded' }
    if position == 'float' then
        win.width = 0.85
        win.height = 0.8
    elseif position == 'bottom' then
        win.height = 0.35
    elseif position == 'right' then
        win.width = 0.4
    end
    if name then
        win.title = ' ' .. icons.terminal .. ' ' .. name .. ' '
        win.title_pos = 'center'
    end

    return {
        count = count,
        cwd = cwd or root_dir(),
        start_insert = true,
        auto_insert = true,
        auto_close = false,
        win = win,
    }
end

local function terminal_list()
    return Snacks.terminal.list()
end

local function valid_terminal(terminal)
    return terminal and terminal.buf and api.nvim_buf_is_valid(terminal.buf)
end

local function remember(terminal)
    if valid_terminal(terminal) then
        last_terminal = terminal
    end
    return terminal
end

local function annotate(terminal, metadata)
    if valid_terminal(terminal) then
        vim.b[terminal.buf].enough_terminal = metadata
    end
    return remember(terminal)
end

local function toggle_terminal(name, position, count, cwd)
    cwd = cwd or root_dir()
    local terminal = Snacks.terminal.toggle(nil, term_opts(position, count, cwd, name))
    return annotate(terminal, { name = name, position = position, count = count, cwd = cwd })
end

local function fresh_count()
    local count = next_terminal_id
    next_terminal_id = next_terminal_id + 1
    return count
end

local function terminal_data(terminal)
    local bufnr = terminal.buf
    if not bufnr or not api.nvim_buf_is_valid(bufnr) then
        return {}
    end
    local data = vim.deepcopy(vim.b[bufnr].snacks_terminal or {})
    return vim.tbl_extend('force', data, vim.b[bufnr].enough_terminal or {})
end

local function current_terminal()
    local bufnr = api.nvim_get_current_buf()
    for _, terminal in ipairs(terminal_list()) do
        if terminal.buf == bufnr then
            return terminal
        end
    end
end

local function focus(terminal)
    if not valid_terminal(terminal) then
        return
    end
    remember(terminal)
    terminal:show():focus()
end

-- Hide the focused terminal, or restore the most recently used one unchanged.
local function toggle_last_terminal()
    local terminal = current_terminal()
    if terminal then
        remember(terminal):hide()
        return
    end

    if valid_terminal(last_terminal) then
        focus(last_terminal)
        return
    end

    toggle_terminal('shell', 'bottom', 1)
end

local function select_terminal(callback)
    local terminals = terminal_list()
    if #terminals == 0 then
        vim.notify('No terminals are running', vim.log.levels.WARN)
        return
    end

    vim.ui.select(terminals, {
        prompt = 'Terminal',
        format_item = function(terminal)
            local data = terminal_data(terminal)
            local command = data.cmd or vim.o.shell
            if type(command) == 'table' then
                command = table.concat(command, ' ')
            end
            local name = data.name or ('terminal ' .. tostring(data.id or '?'))
            return ('%s %s  %s  %s %s'):format(icons.terminal, name, command, icons.cwd, data.cwd or '')
        end,
    }, function(terminal)
        if terminal then
            callback(remember(terminal))
        end
    end)
end

local function with_terminal(callback)
    local terminal = current_terminal()
    if terminal then
        callback(terminal)
    else
        select_terminal(callback)
    end
end

local function stop(terminal)
    local bufnr = terminal.buf
    if valid_terminal(last_terminal) and terminal.buf == last_terminal.buf then
        last_terminal = nil
    end
    if bufnr and api.nvim_buf_is_valid(bufnr) then
        local job = vim.b[bufnr].terminal_job_id
        if job then
            pcall(vim.fn.jobstop, job)
        end
    end
    pcall(function()
        terminal:close()
    end)
    if bufnr and api.nvim_buf_is_valid(bufnr) then
        pcall(api.nvim_buf_delete, bufnr, { force = true })
    end
end

api.nvim_create_user_command('TerminalToggle', toggle_last_terminal, {
    desc = 'Toggle most recently used terminal',
})

api.nvim_create_user_command('TerminalFloat', function()
    toggle_terminal('float', 'float', 2)
end, { desc = 'Toggle floating terminal' })

api.nvim_create_user_command('TerminalHorizontal', function()
    toggle_terminal('horizontal', 'bottom', 3)
end, { desc = 'Toggle horizontal terminal' })

api.nvim_create_user_command('TerminalVertical', function()
    toggle_terminal('vertical', 'right', 4)
end, { desc = 'Toggle vertical terminal' })

api.nvim_create_user_command('TerminalDirectory', function()
    toggle_terminal('file directory', 'bottom', 5, file_dir())
end, { desc = 'Toggle terminal in current file directory' })

api.nvim_create_user_command('TerminalProject', function()
    toggle_terminal('project', 'bottom', 6, root_dir())
end, { desc = 'Toggle terminal at project root' })

api.nvim_create_user_command('TerminalNew', function()
    vim.ui.input({
        prompt = 'Terminal name',
        default = 'shell-' .. tostring(next_terminal_id - 19),
    }, function(name)
        if not name or vim.trim(name) == '' then
            return
        end
        local count = fresh_count()
        local cwd = root_dir()
        annotate(Snacks.terminal.open(nil, term_opts('float', count, cwd, name)), {
            name = name,
            position = 'float',
            count = count,
            cwd = cwd,
        })
    end)
end, { desc = 'Open a named terminal' })

api.nvim_create_user_command('TerminalSelect', function()
    select_terminal(focus)
end, { desc = 'Select a running terminal' })

api.nvim_create_user_command('TerminalRestart', function()
    with_terminal(function(terminal)
        local data = terminal_data(terminal)
        local position = data.position or 'float'
        local count = tonumber(data.count) or tonumber(data.id) or fresh_count()
        local opts = term_opts(position, count, data.cwd, data.name)
        opts.env = data.env
        local command = data.cmd
        stop(terminal)
        vim.schedule(function()
            annotate(Snacks.terminal.open(command, opts), {
                name = data.name,
                position = position,
                count = count,
                cwd = data.cwd,
            })
        end)
    end)
end, { desc = 'Restart a terminal' })

api.nvim_create_user_command('TerminalStop', function()
    with_terminal(stop)
end, { desc = 'Stop a terminal process' })

-- Window navigation also updates what <C-\> will restore next.
api.nvim_create_autocmd('BufEnter', {
    group = api.nvim_create_augroup('EnoughTerminalHistory', { clear = true }),
    callback = function(args)
        if vim.bo[args.buf].filetype ~= 'snacks_terminal' then
            return
        end
        for _, terminal in ipairs(terminal_list()) do
            if terminal.buf == args.buf then
                remember(terminal)
                return
            end
        end
    end,
})

return {
    {
        'folke/snacks.nvim',
        lazy = false,
        opts = {
            terminal = {
                enabled = true,
                win = { style = 'terminal' },
            },
        },
    },
}
