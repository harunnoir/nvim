return {
    -- {
    --     'milanglacier/minuet-ai.nvim',
    --     event = 'InsertEnter',
    --     config = function()
    --         require('minuet').setup({
    --             blink = { enable_auto_complete = false },
    --         })
    --     end,
    -- },
    {
        dir = '/home/abait-el/projects/tellme.nvim',
        name = 'tellme.nvim',
        lazy = false,
        opts = {},
    },
    {
        'olimorris/codecompanion.nvim',
        cmd = {
            'CodeCompanion',
            'CodeCompanionActions',
            'CodeCompanionChat',
        },
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        opts = {
            interactions = {
                chat = {
                    adapter = {
                        name = 'openai_responses',
                        model = 'gpt-5.6-luna',
                    },
                },
                inline = {
                    adapter = {
                        name = 'openai_responses',
                        model = 'gpt-5.6-luna',
                    },
                },
            },
            adapters = {
                http = {
                    openai_responses = function()
                        return require('codecompanion.adapters').extend('openai_responses', {
                            env = { api_key = 'OPENAI_API_KEY' },
                        })
                    end,
                },
            },
            display = {
                action_palette = { provider = 'snacks' },
            },
        },
    },
    {
        'ThePrimeagen/99',
        lazy = false,
        config = function()
            local _99 = require('99')
            local basename = vim.fs.basename(vim.uv.cwd())

            _99.setup({
                provider = _99.Providers.OpenCodeProvider,
                -- model = 'openai/gpt-5.6-sol',
                model = 'openai/gpt-5.6-sol-fast',

                logger = {
                    level = _99.DEBUG,
                    path = '/tmp/' .. basename .. '.99.debug',
                    print_on_error = true,
                },

                -- Keep generated files inside the project so OpenCode does not
                -- require external_directory permission.
                tmp_dir = './tmp',

                completion = {
                    source = 'native',
                    custom_rules = {},
                    files = {},
                },

                md_files = {
                    'AGENTS.md',
                },
            })
        end,
    },
}
