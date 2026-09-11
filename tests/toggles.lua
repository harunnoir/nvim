-- Verify Learning Mode is buffer-local, blocks contradictory toggles, and
-- restores the exact assistance state that existed before it was enabled.
local toggles = require('config.toggles')
local primary = vim.api.nvim_create_buf(true, false)
local secondary = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(primary)

vim.bo[primary].syntax = 'lua'
vim.b[primary].completion = true
vim.b[primary].autoformat = false
vim.b[primary].lsp_enabled = true
vim.diagnostic.enable(true, { bufnr = primary })

vim.b[secondary].completion = true
vim.b[secondary].autoformat = true
vim.b[secondary].lsp_enabled = true
vim.diagnostic.enable(true, { bufnr = secondary })

assert(toggles.diagnostic_severity(primary) == nil, 'warnings should start enabled')
toggles.toggle_warnings(primary)
assert(toggles.diagnostic_severity(primary) == vim.diagnostic.severity.ERROR, 'warnings toggle should use errors only')
toggles.toggle_warnings(primary)
assert(toggles.diagnostic_severity(primary) == nil, 'warnings should restore')

toggles.toggle_learning(primary)
assert(vim.b[primary].learning_mode == true, 'learning mode did not enable')
assert(vim.bo[primary].syntax == 'lua', 'learning mode changed syntax highlighting')
assert(vim.b[primary].completion == false, 'completion stayed enabled')
assert(vim.b[primary].autoformat == false, 'format on save stayed enabled')
assert(vim.b[primary].lsp_enabled == false, 'LSP stayed enabled')
assert(not vim.diagnostic.is_enabled({ bufnr = primary }), 'diagnostics stayed enabled')

assert(vim.b[secondary].learning_mode ~= true, 'learning mode leaked into another buffer')
assert(vim.b[secondary].completion == true, 'completion changed in another buffer')
assert(vim.b[secondary].autoformat == true, 'formatting changed in another buffer')
assert(vim.diagnostic.is_enabled({ bufnr = secondary }), 'diagnostics changed in another buffer')

-- Individual toggles must not claim to re-enable assistance under Learning Mode.
toggles.toggle_completion(primary)
assert(vim.b[primary].completion == false, 'completion bypassed learning mode')

toggles.toggle_learning(primary)
assert(vim.b[primary].learning_mode == false, 'learning mode did not disable')
assert(vim.bo[primary].syntax == 'lua', 'syntax highlighting was not preserved')
assert(vim.b[primary].completion == true, 'completion state was not restored')
assert(vim.b[primary].autoformat == false, 'format state was not restored')
assert(vim.b[primary].lsp_enabled == true, 'LSP state was not restored')
assert(vim.diagnostic.is_enabled({ bufnr = primary }), 'diagnostics state was not restored')

local before_wrap = vim.wo.wrap
toggles.toggle_option('wrap', 'line wrapping')
assert(vim.wo.wrap ~= before_wrap, 'window option did not toggle')
toggles.toggle_option('wrap', 'line wrapping')
assert(vim.wo.wrap == before_wrap, 'window option did not restore')

local before_laststatus = vim.o.laststatus
local before_number = vim.wo.number
local before_signcolumn = vim.wo.signcolumn
toggles.minimal()
assert(toggles.is_minimal(), 'minimal mode did not enable')
assert(vim.o.laststatus == 0, 'minimal mode did not hide the statusline')
assert(not vim.wo.number, 'minimal mode did not hide line numbers')
assert(vim.wo.signcolumn == 'no', 'minimal mode did not hide the sign column')
vim.cmd.vsplit()
local minimal_split = vim.api.nvim_get_current_win()
assert(not vim.wo.number, 'a new split did not inherit minimal mode')
toggles.normal()
assert(not toggles.is_minimal(), 'normal mode did not restore')
assert(vim.o.laststatus == before_laststatus, 'normal mode did not restore the statusline')
assert(vim.wo.number == before_number, 'normal mode did not restore line numbers')
assert(vim.wo.signcolumn == before_signcolumn, 'normal mode did not restore the sign column')
assert(vim.wo.number == before_number, 'a split created in minimal mode did not restore normal options')
vim.api.nvim_win_close(minimal_split, true)

vim.api.nvim_buf_delete(primary, { force = true })
vim.api.nvim_buf_delete(secondary, { force = true })
