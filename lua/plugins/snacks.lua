--[[
Snacks.

One spec for the whole config, because the other feature files consume Snacks
instead of declaring it: pickers, terminal, git tools, notifications, and the
lazygit wrapper all come from here. If you add a Snacks option, add it here.

`lazy = false` is required -- Snacks replaces several built-ins at startup
(notifications, terminal buffers, the statusline spinner) and expects to be
there before the first file is opened.

`scroll` stays off: smooth scrolling redraws continuously and costs more than it
gives on the file sizes this config deals with. `bigfile` and `quickfile` are
the switches that actually matter, so they are on.
]]
return {
    {
        'folke/snacks.nvim',
        lazy = false,
        opts = {
            -- Keep these three explicit: turning them off is the only way to
            -- notice they were doing something.
            bigfile = { enabled = true },
            indent = { enabled = true },
            quickfile = { enabled = true },

            -- 2500ms is long enough to read a message you did not expect and
            -- short enough not to stack up during a fast session.
            notifier = { enabled = true, timeout = 2500 },
            input = { enabled = true },
            scope = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
            bufdelete = { enabled = true },

            -- `win.style = 'terminal'` is what makes a Snacks terminal look like
            -- a terminal instead of an editor window.
            terminal = { enabled = true, win = { style = 'terminal' } },

            git = { enabled = true },
            gitbrowse = { enabled = true },
            lazygit = { enabled = true },

            picker = {
                enabled = true,
                -- Turns `vim.ui.select` (`:TerminalSelect`, Mason prompts) into
                -- the same picker everything else uses.
                ui_select = true,
                layout = { preset = 'ivy', cycle = true },
            },
        },
    },
}
