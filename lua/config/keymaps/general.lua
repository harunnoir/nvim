--[[
General editing mappings (no <leader> prefix).
]]
local select = 'nvim-treesitter-textobjects.select'
local move = 'nvim-treesitter-textobjects.move'

local M = {}

function M.setup(map, opts, format, close_other_buffers, resize)
    -- <Space> and <leader> are the same key; disable space in normal/visual
    map({ 'n', 'x' }, '<Space>', '<Nop>', { silent = true })

    -- Clear search highlight
    map('n', '<Esc>', '<cmd>nohlsearch<cr>', opts('Clear search highlight'))

    -- Write file
    map({ 'n', 'i', 'x' }, '<C-s>', '<cmd>write<cr>', opts('Write file'))

    -- Alternate buffer
    map('n', '<BS>', '<C-^>', opts('Alternate buffer'))

    -- Screen-line movement when wrapped
    map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
    map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

    -- Indent/outdent keep selection
    map('x', '<', '<gv', opts('Outdent selection'))
    map('x', '>', '>gv', opts('Indent selection'))

    -- Paste without replacing register
    map('x', 'p', 'P', opts('Paste without replacing the register'))

    -- Move lines/selections
    map('n', ']e', '<cmd>move .+1<cr>==', opts('Move line down'))
    map('n', '[e', '<cmd>move .-2<cr>==', opts('Move line up'))
    map('x', ']e', ":move '>+1<cr>gv=gv", opts('Move selection down'))
    map('x', '[e', ":move '<-2<cr>gv=gv", opts('Move selection up'))

    -- Undo tree
    map('n', '<leader>uu', '<cmd>UndotreeToggle<cr>', opts('Toggle the undo tree'))

    -- Surround (Mini Surround, vim-surround style)
    map('n', 'yss', 'ys_', opts('Surround the current line', { remap = true }))
    map('n', 'gsn', function()
        require('mini.surround').update_n_lines()
    end, opts('Set the surround search lines'))

    -- Text objects by syntax node
    map({ 'x', 'o' }, 'af', function()
        require(select).select_textobject('@function.outer', 'textobjects')
    end, opts('Around function'))
    map({ 'x', 'o' }, 'if', function()
        require(select).select_textobject('@function.inner', 'textobjects')
    end, opts('Inside function'))
    map({ 'x', 'o' }, 'ac', function()
        require(select).select_textobject('@class.outer', 'textobjects')
    end, opts('Around class'))
    map({ 'x', 'o' }, 'ic', function()
        require(select).select_textobject('@class.inner', 'textobjects')
    end, opts('Inside class'))
    map({ 'n', 'x', 'o' }, ']f', function()
        require(move).goto_next_start('@function.outer', 'textobjects')
    end, opts('Next function'))
    map({ 'n', 'x', 'o' }, '[f', function()
        require(move).goto_previous_start('@function.outer', 'textobjects')
    end, opts('Previous function'))

    -- Flash: s to jump, S for treesitter, r as operator
    map({ 'n', 'x', 'o' }, 's', function()
        require('flash').jump()
    end, opts('Flash jump'))
    map({ 'n', 'x', 'o' }, 'S', function()
        require('flash').treesitter()
    end, opts('Flash Tree-sitter'))
    map('o', 'r', function()
        require('flash').remote()
    end, opts('Flash remote'))
end

return M