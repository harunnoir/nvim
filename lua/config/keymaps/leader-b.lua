--[[
<leader>b: buffer management.
]]
local M = {}

function M.setup(map, opts)
    map('n', '<leader>bb', function()
        Snacks.picker.buffers()
    end, opts('Buffers'))
    map('n', '<leader>bn', '<cmd>bnext<cr>', opts('Next buffer'))
    map('n', '<leader>bp', '<cmd>bprevious<cr>', opts('Previous buffer'))
    map('n', '<leader>bd', function()
        Snacks.bufdelete()
    end, opts('Delete buffer'))
    map('n', '<leader>bo', function()
        local current = vim.api.nvim_get_current_buf()
        for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
            if buffer ~= current and vim.api.nvim_buf_is_loaded(buffer) and vim.bo[buffer].buflisted then
                pcall(vim.api.nvim_buf_delete, buffer, {})
            end
        end
    end, opts('Delete other buffers'))
end

return M