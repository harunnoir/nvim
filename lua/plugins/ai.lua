--[[
AI: one plugin, 99, driving `opencode`.

There is no in-editor chat here on purpose. Chat invites a second, weaker way
to do work you already have a terminal for, so the only AI surface is one that
acts on what you selected.

`VeryLazy` because nothing in this file needs to exist at startup: the mappings
in `config/keymaps.lua` call into 99 when you press them, not before.
]]
return {
    {
        'ThePrimeagen/99',
        event = 'VeryLazy',
        config = function()
            local ai = require('99')

            ai.setup({
                provider = ai.Providers.OpenCodeProvider,
                model = 'openai/gpt-5.6-sol-fast',

                logger = {
                    level = ai.DEBUG,
                    -- Named after the project, so two projects open at once do
                    -- not overwrite each other's log.
                    path = '/tmp/' .. vim.fs.basename(vim.uv.cwd()) .. '.99.debug',
                    print_on_error = true,
                },

                -- Inside the project on purpose: 99 writing to `/tmp` would make
                -- opencode ask for `external_directory` permission every run.
                tmp_dir = './tmp',

                completion = {
                    source = 'native',
                    custom_rules = {},
                    files = {},
                },

                -- Instructions 99 should read before acting on this project.
                md_files = {
                    'AGENTS.md',
                },
            })
        end,
    },
}
