local icons = require('config.icons')

assert(icons.terminal and icons.error and icons.learning, 'icon table is incomplete')
assert(vim.fn.exists(':KeymapManual') == 2, 'KeymapManual command is missing')
assert(vim.fn.maparg(']t', 'n') ~= '', 'next TODO mapping is missing')
assert(vim.fn.maparg('<leader>qt', 'n') ~= '', 'TODO list mapping is missing')
assert(vim.fn.maparg('<leader>aa', 'n') ~= '', 'select-all mapping is missing')
assert(vim.fn.maparg('<leader>ay', 'n') ~= '', 'copy-all mapping is missing')
assert(vim.fn.maparg('<leader>ax', 'n') ~= '', 'cut-all mapping is missing')
assert(vim.fn.maparg('<leader>wm', 'n') ~= '', 'maximize mapping is missing')
assert(vim.fn.maparg('<leader>mm', 'n') ~= '', 'minimal mode mapping is missing')
assert(vim.fn.maparg('<leader>mn', 'n') ~= '', 'normal mode mapping is missing')
assert(vim.fn.exists(':ModeMinimal') == 2, 'ModeMinimal command is missing')
assert(vim.fn.exists(':ModeNormal') == 2, 'ModeNormal command is missing')
assert(vim.fn.maparg('<leader>rr', 'n') ~= '', 'REPL restart mapping is missing')
assert(vim.fn.exists(':Maximize') == 2, 'Maximize command is missing')
assert(vim.fn.maparg('s', 'n', false, true).desc == 'Flash jump', 'Flash mapping is missing')
assert(vim.fn.maparg('ys', 'n') ~= '', 'surround add mapping is missing')
assert(vim.fn.maparg('ds', 'n') ~= '', 'surround delete mapping is missing')
assert(vim.fn.maparg('cs', 'n') ~= '', 'surround replace mapping is missing')
assert(vim.fn.maparg('gcc', 'n') ~= '', 'line comment mapping is missing')
assert(vim.fn.maparg('gbc', 'n') ~= '', 'block comment mapping is missing')
assert(vim.fn.maparg('gc', 'n') ~= '', 'line comment operator is missing')
assert(vim.fn.maparg('gb', 'n') ~= '', 'block comment operator is missing')
assert(vim.fn.maparg('<leader>uu', 'n') ~= '', 'undo tree mapping is missing')
assert(vim.fn.maparg('gS', 'n') ~= '', 'splitjoin toggle mapping is missing')
assert(vim.fn.maparg('<M-j>', 'x') ~= '', 'mini.move visual mapping is missing')
assert(vim.fn.maparg('<leader>gd', 'n') ~= '', 'diff view mapping is missing')
assert(vim.fn.maparg('<leader>gD', 'n') ~= '', 'file history mapping is missing')

local comment_api = require('Comment.api')
local comment_buffer = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(comment_buffer)
vim.bo[comment_buffer].filetype = 'c'
vim.api.nvim_buf_set_lines(comment_buffer, 0, -1, false, { 'printf("hi");' })
vim.api.nvim_win_set_cursor(0, { 1, 0 })

comment_api.toggle.blockwise.current()
local commented = vim.api.nvim_buf_get_lines(comment_buffer, 0, 1, false)[1]
assert(commented:match('^%s*/%*%s'), 'block comment was not added: ' .. commented)
comment_api.toggle.blockwise.current()
local restored = vim.api.nvim_buf_get_lines(comment_buffer, 0, 1, false)[1]
assert(restored == 'printf("hi");', 'block comment was not removed: ' .. restored)

comment_api.toggle.linewise.current()
commented = vim.api.nvim_buf_get_lines(comment_buffer, 0, 1, false)[1]
assert(commented:match('^//%s'), 'line comment was not added: ' .. commented)
comment_api.toggle.linewise.current()
restored = vim.api.nvim_buf_get_lines(comment_buffer, 0, 1, false)[1]
assert(restored == 'printf("hi");', 'line comment was not removed: ' .. restored)
vim.api.nvim_buf_delete(comment_buffer, { force = true })

dofile(vim.fn.stdpath('config') .. '/tests/toggles.lua')
