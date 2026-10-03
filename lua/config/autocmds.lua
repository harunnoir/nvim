-- Automatic behavior. Everything here is a policy, not a preference:
-- each block explains what would go wrong without it.
local api = vim.api

local function group(name)
    return api.nvim_create_augroup('enough_' .. name, { clear = true })
end

-- Flash the text you just yanked so you can see what you actually grabbed.
api.nvim_create_autocmd('TextYankPost', {
    group = group('yank'),
    desc = 'Flash yanked text',
    callback = function()
        vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 })
    end,
})

-- Reload files changed outside Neovim. Returning to the window and leaving a
-- terminal are the two moments this is least surprising.
api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
    group = group('checktime'),
    desc = 'Reload externally changed files',
    callback = function()
        if vim.bo.buftype ~= 'nofile' then
            vim.cmd.checktime()
        end
    end,
})

-- Create missing directories on write, so a new nested path does not need every
-- parent created first. URIs (`:w https://...`) are skipped.
api.nvim_create_autocmd('BufWritePre', {
    group = group('create_parent'),
    desc = 'Create parent directories on write',
    callback = function(args)
        local file = args.match
        if file ~= '' and not file:match('^%w%w+://') then
            vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
        end
    end,
})

-- Return to where you left off. The bounds check matters: a stale mark pointing
-- past the end of a rewritten file would error on every open.
api.nvim_create_autocmd('BufReadPost', {
    group = group('last_position'),
    desc = 'Restore the last cursor position',
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

-- Read-only panes. Unlisting keeps `:bnext` and the buffer picker focused on
-- real work, and `q` closes them the way it closes any other window.
api.nvim_create_autocmd('FileType', {
    group = group('read_only_panes'),
    pattern = { 'checkhealth', 'help', 'lspinfo', 'qf', 'startuptime' },
    desc = 'Make info windows transient',
    callback = function(args)
        vim.bo[args.buf].buflisted = false
        require('config.keymaps').close_with_q(args.buf)
    end,
})

-- Terminals are scratch workspaces: editor chrome is noise there, and leaving
-- them out of the buffer list keeps `<leader>b` useful.
api.nvim_create_autocmd({ 'TermOpen', 'BufEnter' }, {
    group = group('terminal'),
    desc = 'Strip editor chrome from terminals',
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

-- Per-filetype indentation and line length.
--   { shiftwidth, expandtab, colorcolumn, wrap?, spell? }
-- `colorcolumn` marks the limit the formatter will respect, so you see the
-- problem before the formatter silently reflows it. 42-school caps C at 80.
local filetypes = {
    c = { 4, false, '80,120' },
    cpp = { 4, false, '100,120' },
    python = { 4, true, '79' },
    lua = { 4, true, '120' },
    sh = { 4, true, '100' },
    make = { 8, false, '100' },
    -- Data and markup files use 2 spaces and wrap, and prose gets spellcheck.
    json = { 2, true, '100' },
    jsonc = { 2, true, '100' },
    yaml = { 2, true, '100' },
    toml = { 2, true, '100' },
    markdown = { 2, true, '100', true, true },
}

api.nvim_create_autocmd('FileType', {
    group = group('filetype_options'),
    pattern = vim.tbl_keys(filetypes),
    desc = 'Apply per-filetype editing options',
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
