local M = {}
local modules = require('modules')
local languages = require('config.languages')
local map = vim.keymap.set

local repl_enabled = modules.repl
    and languages.python.enabled
    and type(languages.python.repl) == 'table'
    and #languages.python.repl > 0

local debug_enabled = modules.debug and vim.iter(languages):any(function(_, profile)
    return type(profile) == 'table' and profile.enabled and profile.debugger ~= nil
end)

local school42_enabled = modules.school42
    and ((languages.c and languages.c.enabled) or (languages.cpp and languages.cpp.enabled))

local function opts(description, extra)
    return vim.tbl_extend('force', { silent = true, desc = description }, extra or {})
end

local function delete_other_buffers()
    local current = vim.api.nvim_get_current_buf()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if buffer ~= current and vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].buflisted then
            pcall(vim.api.nvim_buf_delete, buffer, {})
        end
    end
end

local function format(range)
    local options = { async = true, lsp_format = 'fallback' }
    if range then
        local first = vim.api.nvim_buf_get_mark(0, '<')
        local last = vim.api.nvim_buf_get_mark(0, '>')
        options.range = {
            start = { first[1], first[2] },
            ['end'] = { last[1], last[2] },
        }
    end
    require('conform').format(options)
end

local function resize(command)
    return function()
        vim.cmd(command)
    end
end

function M.setup()
    -- General editing.
    map({ 'n', 'x' }, '<Space>', '<Nop>', { silent = true })
    map('n', '<Esc>', '<cmd>nohlsearch<cr>', opts('Clear search highlight'))
    map({ 'n', 'i', 'x' }, '<C-s>', '<cmd>write<cr>', opts('Write file'))
    map('n', '<BS>', '<C-^>', opts('Alternate buffer'))

    -- Whole-buffer actions stay under one small, predictable prefix.
    map('n', '<leader>aa', 'ggVG', opts('Select whole buffer'))
    map('n', '<leader>ay', '<cmd>%yank +<cr>', opts('Copy whole buffer'))
    map('n', '<leader>ax', '<cmd>%delete +<cr>', opts('Cut whole buffer'))

    map('n', '<leader>?', '<cmd>KeymapManual<cr>', opts('Keymap manual'))
    map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
    map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
    map('x', '<', '<gv', opts('Outdent selection'))
    map('x', '>', '>gv', opts('Indent selection'))
    map('x', 'p', 'P', opts('Paste without replacing register'))
    map('n', ']e', '<cmd>move .+1<cr>==', opts('Move line down'))
    map('n', '[e', '<cmd>move .-2<cr>==', opts('Move line up'))
    map('x', ']e', ":move '>+1<cr>gv=gv", opts('Move selection down'))
    map('x', '[e', ":move '<-2<cr>gv=gv", opts('Move selection up'))

    -- Lists and diagnostics navigation.
    map('n', ']b', '<cmd>bnext<cr>', opts('Next buffer'))
    map('n', '[b', '<cmd>bprevious<cr>', opts('Previous buffer'))
    map('n', ']q', '<cmd>cnext<cr>', opts('Next quickfix item'))
    map('n', '[q', '<cmd>cprevious<cr>', opts('Previous quickfix item'))
    map('n', ']d', function()
        vim.diagnostic.jump({
            count = 1,
            float = true,
            severity = require('config.toggles').diagnostic_severity(),
        })
    end, opts('Next diagnostic'))
    map('n', '[d', function()
        vim.diagnostic.jump({
            count = -1,
            float = true,
            severity = require('config.toggles').diagnostic_severity(),
        })
    end, opts('Previous diagnostic'))

    -- Windows: focus, resize, then move with the same directions.
    map('n', '<C-h>', '<C-w>h', opts('Focus left window'))
    map('n', '<C-j>', '<C-w>j', opts('Focus lower window'))
    map('n', '<C-k>', '<C-w>k', opts('Focus upper window'))
    map('n', '<C-l>', '<C-w>l', opts('Focus right window'))
    map({ 'n', 't' }, '<A-h>', resize('vertical resize -2'), opts('Decrease window width'))
    map({ 'n', 't' }, '<A-j>', resize('resize +2'), opts('Increase window height'))
    map({ 'n', 't' }, '<A-k>', resize('resize -2'), opts('Decrease window height'))
    map({ 'n', 't' }, '<A-l>', resize('vertical resize +2'), opts('Increase window width'))
    map('n', '<leader>wv', '<C-w>v', opts('Split vertically'))
    map('n', '<leader>ws', '<C-w>s', opts('Split horizontally'))
    map('n', '<leader>wc', '<C-w>c', opts('Close window'))
    map('n', '<leader>wo', '<C-w>o', opts('Keep only this window'))
    map('n', '<leader>we', '<C-w>=', opts('Equalize windows'))
    if modules.ui then
        map('n', '<leader>wm', '<cmd>Maximize<cr>', opts('Toggle window maximize'))
    end
    map('n', '<leader>wh', '<C-w>H', opts('Move window left'))
    map('n', '<leader>wj', '<C-w>J', opts('Move window down'))
    map('n', '<leader>wk', '<C-w>K', opts('Move window up'))
    map('n', '<leader>wl', '<C-w>L', opts('Move window right'))
    map('n', '<leader>wH', resize('vertical resize -2'), opts('Decrease window width'))
    map('n', '<leader>wJ', resize('resize +2'), opts('Increase window height'))
    map('n', '<leader>wK', resize('resize -2'), opts('Decrease window height'))
    map('n', '<leader>wL', resize('vertical resize +2'), opts('Increase window width'))

    -- Toggles remain available even when coding modules are disabled.
    local toggles = require('config.toggles')
    map('n', '<leader>td', toggles.toggle_diagnostics, opts('Toggle diagnostics'))
    map('n', '<leader>tv', toggles.toggle_virtual_text, opts('Toggle diagnostic virtual text'))
    map('n', '<leader>tW', toggles.toggle_warnings, opts('Toggle warnings'))
    map('n', '<leader>tl', toggles.toggle_lsp, opts('Toggle LSP'))
    map('n', '<leader>tc', toggles.toggle_completion, opts('Toggle completion'))
    map('n', '<leader>tf', toggles.toggle_format, opts('Toggle format on save'))
    map('n', '<leader>th', toggles.toggle_inlay_hints, opts('Toggle inlay hints'))
    map('n', '<leader>tm', toggles.toggle_learning, opts('Toggle learning mode'))
    map('n', '<leader>tw', function()
        toggles.toggle_option('wrap', 'line wrapping')
    end, opts('Toggle wrap'))
    map('n', '<leader>ts', function()
        toggles.toggle_option('spell', 'spelling')
    end, opts('Toggle spell'))
    map('n', '<leader>tn', function()
        toggles.toggle_option('relativenumber', 'relative numbers')
    end, opts('Toggle relative numbers'))

    map('t', '<Esc><Esc>', '<C-\\><C-n>', opts('Leave terminal mode'))
    map('t', '<C-h>', '<C-\\><C-n><C-w>h', opts('Focus left window'))
    map('t', '<C-j>', '<C-\\><C-n><C-w>j', opts('Focus lower window'))
    map('t', '<C-k>', '<C-\\><C-n><C-w>k', opts('Focus upper window'))
    map('t', '<C-l>', '<C-\\><C-n><C-w>l', opts('Focus right window'))

    if modules.editing then
        -- Editing and text objects.
        -- Mini Surround uses vim-surround-style keys so Flash can own `s`.
        map('n', 'yss', 'ys_', opts('Surround current line', { remap = true }))
        map('n', 'gsn', function()
            MiniSurround.update_n_lines()
        end, opts('Set surround search lines'))

        map({ 'x', 'o' }, 'af', function()
            require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
        end, opts('Around function'))
        map({ 'x', 'o' }, 'if', function()
            require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
        end, opts('Inside function'))
        map({ 'x', 'o' }, 'ac', function()
            require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
        end, opts('Around class'))
        map({ 'x', 'o' }, 'ic', function()
            require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
        end, opts('Inside class'))
        map({ 'n', 'x', 'o' }, ']f', function()
            require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
        end, opts('Next function'))
        map({ 'n', 'x', 'o' }, '[f', function()
            require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
        end, opts('Previous function'))
    end

    if modules.navigation then
        -- Fast navigation. Mini Surround keeps its separate vim-surround-style keys.
        map({ 'n', 'x', 'o' }, 's', function()
            require('flash').jump()
        end, opts('Flash jump'))
        map({ 'n', 'x', 'o' }, 'S', function()
            require('flash').treesitter()
        end, opts('Flash Tree-sitter'))
        map('o', 'r', function()
            require('flash').remote()
        end, opts('Remote flash'))

        -- Buffers: <leader>b.
        map('n', '<leader>bb', function()
            Snacks.picker.buffers()
        end, opts('Buffers'))
        map('n', '<leader>bn', '<cmd>bnext<cr>', opts('Next buffer'))
        map('n', '<leader>bp', '<cmd>bprevious<cr>', opts('Previous buffer'))
        map('n', '<leader>bd', function()
            Snacks.bufdelete()
        end, opts('Delete buffer'))
        map('n', '<leader>bo', delete_other_buffers, opts('Delete other buffers'))

        -- Find and navigation: <leader>f.
        map('n', '<leader>ff', function()
            Snacks.picker.files()
        end, opts('Find files'))
        map('n', '<leader>fg', function()
            Snacks.picker.grep()
        end, opts('Grep project'))
        map({ 'n', 'x' }, '<leader>fw', function()
            Snacks.picker.grep_word()
        end, opts('Grep word'))
        map('n', '<leader>fr', function()
            Snacks.picker.recent()
        end, opts('Recent files'))
        map('n', '<leader>fh', function()
            Snacks.picker.help()
        end, opts('Help tags'))
        map('n', '<leader>fk', '<cmd>KeymapManual<cr>', opts('Keymap manual'))
        map('n', '<leader>fc', function()
            Snacks.picker.files({
                cwd = vim.fn.stdpath('config'),
                title = 'Config Files',
            })
        end, opts('Config files'))
        map('n', '-', '<cmd>Oil<cr>', opts('Open parent directory'))
        map('n', '<leader>fe', '<cmd>Oil<cr>', opts('File explorer'))
        map('n', '<leader>fR', '<cmd>GrugFar<cr>', opts('Find and replace'))
        map('n', ']t', function()
            require('todo-comments').jump_next()
        end, opts('Next TODO comment'))
        map('n', '[t', function()
            require('todo-comments').jump_prev()
        end, opts('Previous TODO comment'))

        -- Problems and lists: <leader>q.
        map('n', '<leader>qq', '<cmd>Trouble diagnostics toggle<cr>', opts('Workspace diagnostics'))
        map('n', '<leader>qb', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', opts('Buffer diagnostics'))
        map('n', '<leader>qs', '<cmd>Trouble symbols toggle focus=false<cr>', opts('Symbols list'))
        map('n', '<leader>ql', '<cmd>Trouble lsp toggle focus=false<cr>', opts('LSP list'))
        map('n', '<leader>qf', '<cmd>Trouble qflist toggle<cr>', opts('Quickfix list'))
        map('n', '<leader>qL', '<cmd>Trouble loclist toggle<cr>', opts('Location list'))
        map('n', '<leader>qt', '<cmd>Trouble todo toggle<cr>', opts('TODO comments'))
    end

    if modules.coding then
        -- Code: <leader>c.
        map('n', '<leader>cm', '<cmd>Mason<cr>', opts('Tool manager'))
        map('n', '<leader>cf', function()
            format(false)
        end, opts('Format code'))
        map('x', '<leader>cf', function()
            format(true)
        end, opts('Format selection'))
    end

    if modules.terminal then
        -- Terminal: <leader>x.
        map({ 'n', 't' }, '<C-\\>', '<cmd>TerminalToggle<cr>', opts('Toggle last terminal'))
        map('n', '<leader>xt', '<cmd>TerminalToggle<cr>', opts('Toggle last terminal'))
        map('n', '<leader>xf', '<cmd>TerminalFloat<cr>', opts('Floating terminal'))
        map('n', '<leader>xh', '<cmd>TerminalHorizontal<cr>', opts('Horizontal terminal'))
        map('n', '<leader>xv', '<cmd>TerminalVertical<cr>', opts('Vertical terminal'))
        map('n', '<leader>xd', '<cmd>TerminalDirectory<cr>', opts('Terminal in file directory'))
        map('n', '<leader>xp', '<cmd>TerminalProject<cr>', opts('Terminal at project root'))
        map('n', '<leader>xn', '<cmd>TerminalNew<cr>', opts('New named terminal'))
        map('n', '<leader>xl', '<cmd>TerminalSelect<cr>', opts('Select terminal'))
        map('n', '<leader>xr', '<cmd>TerminalRestart<cr>', opts('Restart terminal'))
        map('n', '<leader>xq', '<cmd>TerminalStop<cr>', opts('Stop terminal'))
    end

    if repl_enabled then
        -- REPL: <leader>r. Manual execution stays available in learning mode.
        map('n', '<leader>rt', '<cmd>IronRepl<cr>', opts('Toggle REPL'))
        map('n', '<leader>rf', '<cmd>IronFocus<cr>', opts('Focus REPL'))
        map('n', '<leader>rh', '<cmd>IronHide<cr>', opts('Hide REPL'))
        map('n', '<leader>rr', '<cmd>IronRestart<cr>', opts('Restart REPL'))
        map('n', '<leader>rl', function()
            require('iron.core').send_line()
        end, opts('Send line to REPL'))
        map('x', '<leader>rs', function()
            require('iron.core').visual_send()
        end, opts('Send selection to REPL'))
        map('n', '<leader>rb', function()
            require('iron.core').send_code_block(false)
        end, opts('Send code block to REPL'))
        map('n', '<leader>rn', function()
            require('iron.core').send_code_block(true)
        end, opts('Send block and move'))
        map('n', '<leader>rp', function()
            require('iron.core').send_paragraph()
        end, opts('Send paragraph to REPL'))
        map('n', '<leader>ra', function()
            require('iron.core').send_file()
        end, opts('Send file to REPL'))
        map('n', '<leader>ru', function()
            require('iron.core').send_until_cursor()
        end, opts('Send through cursor to REPL'))
    end

    if debug_enabled then
        -- Debug: <leader>d.
        map('n', '<leader>dc', function()
            require('dap').continue()
        end, opts('Continue/start'))
        map('n', '<leader>di', function()
            require('dap').step_into()
        end, opts('Step into'))
        map('n', '<leader>do', function()
            require('dap').step_over()
        end, opts('Step over'))
        map('n', '<leader>dO', function()
            require('dap').step_out()
        end, opts('Step out'))
        map('n', '<leader>dr', function()
            require('dap').run_last()
        end, opts('Run last'))
        map('n', '<leader>dt', function()
            require('dap').terminate()
        end, opts('Terminate'))
        map('n', '<leader>db', function()
            require('dap').toggle_breakpoint()
        end, opts('Toggle breakpoint'))
        map('n', '<leader>dB', function()
            require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end, opts('Conditional breakpoint'))
        map('n', '<leader>du', function()
            require('dapui').toggle()
        end, opts('Toggle debug UI'))
        map({ 'n', 'x' }, '<leader>de', function()
            require('dapui').eval()
        end, opts('Evaluate'))
    end

    if modules.git then
        -- Git: <leader>g.
        map('n', '<leader>gg', function()
            Snacks.lazygit()
        end, opts('Lazygit'))
        map({ 'n', 'x' }, '<leader>go', function()
            Snacks.gitbrowse()
        end, opts('Open in browser'))
        map('n', '<leader>gl', function()
            Snacks.picker.git_log()
        end, opts('Git log'))
        map('n', '<leader>gs', function()
            Snacks.picker.git_status()
        end, opts('Git status'))
        map('n', '<leader>gb', function()
            Snacks.picker.git_branches()
        end, opts('Git branches'))
    end

    if modules.project then
        -- Projects, tasks, and sessions: <leader>p.
        map('n', '<leader>pp', function()
            Snacks.picker.projects()
        end, opts('Projects'))
        map('n', '<leader>pt', '<cmd>OverseerRun<cr>', opts('Run task'))
        map('n', '<leader>po', '<cmd>OverseerToggle<cr>', opts('Toggle task output'))
        map('n', '<leader>pc', '<cmd>OverseerRunCmd<cr>', opts('Run shell command'))
        map('n', '<leader>pa', '<cmd>OverseerTaskAction<cr>', opts('Task action'))
        map('n', '<leader>ps', function()
            require('persistence').load()
        end, opts('Restore session'))
        map('n', '<leader>pS', function()
            require('persistence').select()
        end, opts('Select session'))
        map('n', '<leader>pl', function()
            require('persistence').load({ last = true })
        end, opts('Restore last session'))
    end

    if school42_enabled then
        -- 42-school tools stay out of ordinary code mappings.
        map('n', '<leader>4h', '<cmd>Stdheader<cr>', opts('Insert 42 header'))
        map('n', '<leader>4f', '<cmd>Format42<cr>', opts('Format to 42 norm'))
        map('n', '<leader>4n', '<cmd>Check42<cr>', opts('Run Norminette'))
    end

    if vim.g.neovide then
        local function scale(delta)
            local value = (tonumber(vim.g.neovide_scale_factor) or 1.0) * delta
            vim.g.neovide_scale_factor = math.max(0.5, math.min(3.0, value))
        end
        map('n', '<C-=>', function()
            scale(1.1)
        end, opts('Zoom in'))
        map('n', '<C-->', function()
            scale(1 / 1.1)
        end, opts('Zoom out'))
        map('n', '<C-0>', function()
            vim.g.neovide_scale_factor = 1.0
        end, opts('Reset zoom'))
    end
end

function M.clues()
    -- Group names stay plain: Mini Clue is a key guide, not an icon dashboard.
    local groups = {
        ['4'] = school42_enabled and '42 school' or nil,
        a = 'whole buffer',
        b = modules.navigation and 'buffers' or nil,
        c = modules.coding and 'code' or nil,
        d = debug_enabled and 'debug' or nil,
        f = modules.navigation and 'find/files' or nil,
        g = modules.git and 'git' or nil,
        p = modules.project and 'project/tasks' or nil,
        q = modules.navigation and 'problems/lists' or nil,
        r = repl_enabled and 'REPL' or nil,
        t = 'toggles',
        w = 'windows',
        x = modules.terminal and 'terminal' or nil,
    }

    local result = {}
    for key, description in pairs(groups) do
        if description then
            result[#result + 1] = {
                mode = 'n',
                keys = '<Leader>' .. key,
                desc = '+' .. description,
            }
        end
    end
    return result
end

function M.lsp(bufnr)
    local buffer = { buffer = bufnr }
    map('n', 'gd', vim.lsp.buf.definition, opts('Go to definition', buffer))
    map('n', 'gD', vim.lsp.buf.declaration, opts('Go to declaration', buffer))
    map({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, opts('Code action', buffer))
    map('n', '<leader>cr', vim.lsp.buf.rename, opts('Rename symbol', buffer))
    map('n', '<leader>cd', vim.diagnostic.open_float, opts('Line diagnostics', buffer))
    map('n', '<leader>ck', vim.lsp.buf.signature_help, opts('Signature help', buffer))
    map('n', '<leader>cc', vim.lsp.codelens.run, opts('Run code lens', buffer))
    map('n', '<leader>cC', vim.lsp.codelens.refresh, opts('Refresh code lens', buffer))

    if modules.navigation then
        map('n', '<leader>cs', function()
            Snacks.picker.lsp_symbols()
        end, opts('Document symbols', buffer))
        map('n', '<leader>cS', function()
            Snacks.picker.lsp_workspace_symbols()
        end, opts('Workspace symbols', buffer))
    end
end

function M.gitsigns(bufnr)
    local gs = require('gitsigns')
    local buffer = { buffer = bufnr }
    map('n', ']h', function()
        if vim.wo.diff then
            vim.cmd.normal({ args = { ']c' }, bang = true })
        else
            gs.nav_hunk('next')
        end
    end, opts('Next hunk', buffer))
    map('n', '[h', function()
        if vim.wo.diff then
            vim.cmd.normal({ args = { '[c' }, bang = true })
        else
            gs.nav_hunk('prev')
        end
    end, opts('Previous hunk', buffer))
    map('n', '<leader>gh', gs.preview_hunk, opts('Preview hunk', buffer))
    map({ 'n', 'x' }, '<leader>ga', gs.stage_hunk, opts('Stage hunk', buffer))
    map({ 'n', 'x' }, '<leader>gr', gs.reset_hunk, opts('Reset hunk', buffer))
    map('n', '<leader>gu', gs.undo_stage_hunk, opts('Undo stage hunk', buffer))
    map('n', '<leader>gB', gs.blame_line, opts('Blame line', buffer))
    map('n', '<leader>gd', gs.diffthis, opts('Diff file', buffer))
end

return M
