local icons = require('config.icons')

local function diagnostics_status()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype ~= '' or not vim.diagnostic.is_enabled({ bufnr = bufnr }) then
        return ''
    end

    local counts = vim.diagnostic.count(bufnr)
    local errors_only = require('config.toggles').diagnostic_severity(bufnr) == vim.diagnostic.severity.ERROR
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

local function formatter_status()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].buftype ~= ''
        or vim.b[bufnr].autoformat ~= true
        or require('config.toggles').is_learning(bufnr)
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

    local names = {}
    local seen = {}
    for _, formatter in ipairs(formatters) do
        local name = formatter.name:gsub('^ruff_.*$', 'ruff'):gsub('_', ' ')
        if not seen[name] then
            names[#names + 1] = name
            seen[name] = true
        end
    end
    return icons.format .. ' ' .. table.concat(names, '+')
end

return {
    {
        dir = "/home/abait-el/projects/limei.nvim",
        name = "limei.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("limei").setup({
                styles = {
                    keywords = { bold = true },
                },
            })
            vim.cmd.colorscheme("limei")
        end,
    },
    -- {
    --     'harunnoir/limei.nvim',
    --     lazy = false,
    --     priority = 1000,
    --     opts = {
    --         transparent = false,
    --         matching = { brackets = true, quotes = true, string_delimiters = true },
    --         styles = {
    --             comments = { italic = true },
    --             keywords = { italic = false },
    --             functions = { bold = false },
    --         },
    --     },
    --     config = function(_, opts)
    --         require('limei').setup(opts)
    --         vim.cmd.colorscheme('limei')
    --     end,
    -- },
    {
        'folke/snacks.nvim',
        lazy = false,
        priority = 900,
        opts = {
            bigfile = { enabled = true },
            indent = { enabled = true },
            input = { enabled = true },
            notifier = { enabled = true, timeout = 2500 },
            quickfile = { enabled = true },
            scope = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
        },
    },
    {
        'declancm/maximize.nvim',
        cmd = 'Maximize',
        opts = {
            -- Only enable integrations for plugins this config actually uses.
            plugins = {
                aerial = { enable = false },
                dapui = { enable = true },
                tree = { enable = false },
            },
        },
        config = function(_, opts)
            require('maximize').setup(opts)

            -- Refresh Slimline immediately when the preserved split layout changes.
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
    {
        'sschleemilch/slimline.nvim',
        lazy = false,
        opts = {
            style = 'fg',
            components = {
                left = { 'mode', 'path', 'git' },
                center = {
                    function()
                        local states = {}
                        if require('config.toggles').is_learning() then
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
            configs = { progress = { follow = false } },
            spaces = { components = '', left = '', right = '' },
            disabled_filetypes = { 'snacks_dashboard', 'snacks_terminal', 'iron', 'oil', 'ministarter' },
        },
    },
}
