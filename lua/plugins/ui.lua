--[[
Interface: colorscheme, statusline, window maximize, command line.

Everything that changes what the editor *looks* like, and nothing about what it
does.
]]
local icons = require('config.icons')
local modes = require('config.modes')

---Counts of each diagnostic severity that is currently visible in this buffer.
---Returns nothing at all for a non-file buffer, or when diagnostics are off, so
---the statusline stays empty instead of showing a stale `0`.
local function diagnostics_status()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype ~= '' or not vim.diagnostic.is_enabled({ bufnr = bufnr }) then
        return ''
    end

    local errors_only = modes.diagnostic_severity(bufnr) == vim.diagnostic.severity.ERROR
    local counts = vim.diagnostic.count(bufnr)
    local parts = {}
    local severities = {
        { vim.diagnostic.severity.ERROR, icons.error },
        { vim.diagnostic.severity.WARN, icons.warn },
        { vim.diagnostic.severity.INFO, icons.info },
        { vim.diagnostic.severity.HINT, icons.hint },
    }

    for _, item in ipairs(severities) do
        local severity, icon = item[1], item[2]
        local visible = not errors_only or severity == vim.diagnostic.severity.ERROR
        if visible and (counts[severity] or 0) > 0 then
            parts[#parts + 1] = icon .. ' ' .. counts[severity]
        end
    end
    return table.concat(parts, ' ')
end

---Which formatter will run on the next save.
---Empty when format-on-save is off or learning mode is on, so you are never told
---about a formatter that will not actually run.
local function formatter_status()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype ~= ''
        or vim.b[bufnr].autoformat ~= true
        or modes.is_learning(bufnr)
    then
        return ''
    end

    local ok, conform = pcall(require, 'conform')
    if not ok or not conform.list_formatters_to_run then
        return ''
    end

    local formatters, use_lsp = conform.list_formatters_to_run(bufnr)
    if #formatters == 0 then
        return use_lsp and (icons.format .. ' LSP') or ''
    end

    local names, seen = {}, {}
    for _, formatter in ipairs(formatters) do
        -- `ruff_format` and `ruff_fix` are the same tool doing different jobs.
        local name = formatter.name:gsub('^ruff_.*$', 'ruff'):gsub('_', ' ')
        if not seen[name] then
            names[#names + 1] = name
            seen[name] = true
        end
    end
    return icons.format .. ' ' .. table.concat(names, '+')
end

local specs = {
    -- =====================================================================
    -- Startup colorscheme
    -- =====================================================================
    -- The only theme that applies itself, and the only one that needs a
    -- `config` at all. Everything else in this file's theme list is a
    -- candidate for `<leader>cu`.
    {
        'ptdewey/darkearth-nvim',
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme('darkearth')
        end,
    },

    -- =====================================================================
    -- Window maximize
    -- =====================================================================
    -- `<leader>wm`. Unlike `<leader>wo`, this is reversible: the whole split
    -- layout is remembered and comes back exactly as it was.
    {
        'declancm/maximize.nvim',
        cmd = 'Maximize',
        opts = {
            -- Only wire up integrations for plugins this config actually uses;
            -- the rest would add autocmds and statusline text for nothing.
            plugins = {
                aerial = { enable = false },
                dapui = { enable = true },
                tree = { enable = false },
            },
        },
        config = function(_, opts)
            require('maximize').setup(opts)

            -- The maximized split changes the layout, so Slimline needs to be
            -- redrawn to pick up the MAX indicator.
            vim.api.nvim_create_autocmd('User', {
                group = vim.api.nvim_create_augroup('enough_maximize_status', { clear = true }),
                pattern = { 'WindowMaximizeStart', 'WindowRestoreEnd' },
                callback = function()
                    vim.schedule(function()
                        vim.cmd.redrawstatus()
                    end)
                end,
            })
        end,
    },

    -- =====================================================================
    -- Statusline
    -- =====================================================================
    -- `lazy = false` because a statusline that appears late is worse than none.
    {
        'sschleemilch/slimline.nvim',
        lazy = false,
        opts = {
            style = 'fg',
            components = {
                left = { 'mode', 'path', 'git' },
                -- Transient states worth knowing about without a message: a
                -- maximized split, a recording macro, learning mode.
                center = {
                    function()
                        local states = {}
                        if modes.is_learning() then
                            states[#states + 1] = icons.learning .. ' LEARNING'
                        end
                        if vim.t.maximized then
                            states[#states + 1] = icons.maximize .. ' MAX'
                        end
                        local register = vim.fn.reg_recording()
                        if register ~= '' then
                            states[#states + 1] = icons.recording .. ' @' .. register
                        end
                        return table.concat(states, ' ')
                    end,
                },
                right = {
                    -- Both read live state from `config/toggles`, so the
                    -- statusline never advertises something that is switched off.
                    diagnostics_status,
                    formatter_status,
                    'filetype_lsp',
                },
            },
            hl = {
                base = 'StatusLine',
                base_inactive = 'StatusLineNC',
                primary = 'StatusLine',
                secondary = 'StatusLineNC',
            },
            -- Progress already lives in fidget.nvim, and following the cursor
            -- draws a percentage bar on every window.
            configs = { progress = { follow = false } },
            -- No separators: a statusline with fewer visual edges is easier to
            -- read at a glance.
            spaces = { components = '', left = '', right = '' },
            -- These windows have their own interface already.
            disabled_filetypes = { 'snacks_dashboard', 'snacks_terminal', 'iron', 'oil', 'ministarter' },
        },
    },

    -- =====================================================================
    -- Tree-sitter context: shows current function/class at top of window
    -- =====================================================================
    {
        'nvim-treesitter/nvim-treesitter-context',
        event = 'BufReadPost',
        opts = { max_lines = 3, multiline_threshold = 1 },
    },

    -- =====================================================================
    -- Command line
    -- =====================================================================
    -- Noice floats the command line and `:messages` as one full-width bar at the
    -- top, which is the only way to get rid of the classic bottom line without
    -- losing the prompt.
    --
    -- The other sub-modules are switched off deliberately: `fidget.nvim` already
    -- owns LSP progress, and Snacks already owns notifications, so leaving
    -- Noice's versions on would show the same thing twice.
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = { 'MunifTanjim/nui.nvim' },
        opts = {
            popupmenu = { enabled = false },
            notify = { enabled = false },
            lsp = { progress = { enabled = false } },
            messages = { enabled = true },

            cmdline = {
                enabled = true,
                format = {
                    cmdline = { icon = '', lang = 'vim' },
                    search_down = { kind = 'search', icon = ' /', lang = 'regex' },
                    search_up = { kind = 'search', icon = ' ?', lang = 'regex' },
                    filter = { icon = '$ ', lang = 'bash' },
                    lua = { icon = '', lang = 'lua' },
                    help = { icon = '' },
                    input = { icon = '?' },
                },
                view = 'cmdline_popup',
                opts = {
                    border = 'none',
                    win_options = {
                        winhighlight = { Normal = 'NormalFloat', FloatBorder = 'FloatBorder' },
                    },
                },
            },

            views = {
                cmdline_popup = {
                    position = { row = '50%', col = '50%' },
                    size = { width = '60%', height = 'auto' },
                    border = 'rounded',
                    win_options = { winblend = 0, winhighlight = { Normal = 'NormalFloat', FloatBorder = 'FloatBorder' } },
                },
                messages = {
                    view = 'split',
                    enter = false,
                    size = '20%',
                    position = 'bottom',
                    win_options = { winhighlight = { Normal = 'NormalFloat' } },
                },
            },

            routes = {
                -- Suppress "written" and "search hit BOTTOM/TOP" noise
                { filter = { event = 'msg_show', find = 'written' }, opts = { skip = true } },
                { filter = { event = 'msg_show', find = 'search hit' }, opts = { skip = true } },
            },
        },
    },
}

-- =====================================================================
-- Retro colorschemes
-- =====================================================================
-- Installed and on the runtimepath, but deliberately without a `config`, so
-- none of them applies itself. Two reasons for that shape:
--
--   * `<leader>cu` finds themes by scanning the runtimepath, so a lazy theme
--     would simply not be in the list to pick.
--   * A theme that applies itself at startup means you never know which one is
--     actually on screen.
--
-- So each of these costs one git checkout and nothing else. To use one:
-- `<leader>cu`, or `:colorscheme gruvbox`.
for _, theme in ipairs({
    'ellisonleao/gruvbox.nvim',
    'sainnhe/gruvbox-material',
    'thallada/farout.nvim',
    'neanias/everforest-nvim',
    'rebelot/kanagawa.nvim',
    'xero/miasma.nvim',
    'maxmx03/solarized.nvim',
}) do
    specs[#specs + 1] = { theme, lazy = false }
end

return specs
