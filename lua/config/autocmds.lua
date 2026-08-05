local api = vim.api

local function group(name)
    return api.nvim_create_augroup('enough_' .. name, { clear = true })
end

api.nvim_create_autocmd('TextYankPost', {
    group = group('highlight_yank'),
    callback = function()
        vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 })
    end,
})

api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
    group = group('checktime'),
    callback = function()
        if vim.bo.buftype ~= 'nofile' then
            vim.cmd.checktime()
        end
    end,
})

-- Saving a new nested path should not require creating every directory first.
api.nvim_create_autocmd('BufWritePre', {
    group = group('create_parent'),
    callback = function(args)
        local file = args.match
        if file ~= '' and not file:match('^%w%w+://') then
            vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
        end
    end,
})

api.nvim_create_autocmd('BufReadPost', {
    group = group('last_position'),
    callback = function(args)
        if vim.bo[args.buf].buftype ~= '' then
            return
        end
        local mark = api.nvim_buf_get_mark(args.buf, '"')
        if mark[1] > 0 and mark[1] <= api.nvim_buf_line_count(args.buf) then
            pcall(api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

api.nvim_create_autocmd('FileType', {
    group = group('close_with_q'),
    pattern = { 'checkhealth', 'help', 'lspinfo', 'qf', 'startuptime' },
    callback = function(args)
        vim.bo[args.buf].buflisted = false
        vim.keymap.set('n', 'q', '<cmd>close<cr>', {
            buffer = args.buf,
            silent = true,
            desc = 'Close window',
        })
    end,
})

-- Terminals are temporary workspaces, not ordinary editable buffers.
api.nvim_create_autocmd({ 'TermOpen', 'BufEnter' }, {
    group = group('terminal'),
    callback = function(args)
        if vim.bo[args.buf].buftype ~= 'terminal' then
            return
        end
        vim.bo[args.buf].buflisted = false
        vim.wo.number = false
        vim.wo.relativenumber = false
        vim.wo.signcolumn = 'no'
        vim.wo.foldcolumn = '0'
        vim.wo.spell = false
        vim.cmd.startinsert()
    end,
})

local filetypes = {
    c = { 4, false, '80,120' },
    cpp = { 4, false, '100,120' },
    css = { 2, true, '100' },
    go = { 4, false, '100' },
    html = { 2, true, '100' },
    javascript = { 2, true, '100' },
    javascriptreact = { 2, true, '100' },
    json = { 2, true, '100' },
    jsonc = { 2, true, '100' },
    lua = { 4, true, '120' },
    make = { 8, false, '100' },
    markdown = { 2, true, '100', true, true },
    python = { 4, true, '88' },
    rust = { 4, true, '100' },
    sh = { 4, true, '100' },
    toml = { 2, true, '100' },
    typescript = { 2, true, '100' },
    typescriptreact = { 2, true, '100' },
    yaml = { 2, true, '100' },
}

api.nvim_create_autocmd('FileType', {
    group = group('filetype_options'),
    pattern = vim.tbl_keys(filetypes),
    callback = function(args)
        local settings = filetypes[args.match]
        vim.bo[args.buf].shiftwidth = settings[1]
        vim.bo[args.buf].tabstop = settings[1]
        vim.bo[args.buf].softtabstop = settings[1]
        vim.bo[args.buf].expandtab = settings[2]
        vim.wo.colorcolumn = settings[3]
        if settings[4] ~= nil then
            vim.wo.wrap = settings[4]
        end
        if settings[5] ~= nil then
            vim.wo.spell = settings[5]
        end
    end,
})
