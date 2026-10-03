--[[
Plugin manager.

There is no module list, no `enabled` switch, and no importer beyond this file.
The specs are plain tables in `lua/plugins/`, one file per feature area, and
lazy.nvim merges them. If a plugin is not in one of those files, it is not
installed; if it is there, it is on.

The priority values inside each file are what decide who claims a key first.
]]
local M = {}

---Install lazy.nvim itself, if it is not already there.
---Cloning instead of downloading a tarball means a later `Lazy! update` works
---without this step being repeated.
function M.bootstrap()
    local path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
    if vim.uv.fs_stat(path) then
        return path
    end

    local output = vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        'https://github.com/folke/lazy.nvim.git',
        path,
    })
    if vim.v.shell_error ~= 0 then
        error('Failed to install lazy.nvim:\n' .. output)
    end
    return path
end

function M.setup()
    vim.opt.rtp:prepend(M.bootstrap())

    require('lazy').setup({
        -- Every file in `lua/plugins/` is a spec, and that is the whole plugin
        -- list: no feature switches, no second list to keep in step. Add a file
        -- there, and its plugins are installed.
        spec = { { import = 'plugins' } },
        install = { colorscheme = { 'farout' } },

        -- Plugins are pinned by whatever their own upstream release recommends.
        -- A spec that wants a specific version says so with `version`; nothing
        -- is pinned globally, so a tagged release stays tagged.
        defaults = { lazy = true, version = false },

        -- Reinstall a plugin the moment its spec file changes. Worth it in a
        -- config this small: it means editing a spec and reloading is enough.
        change_detection = { notify = false },

        -- Ask before an update pulls anything in. A config that changes itself
        -- while you are working is a config you cannot reason about.
        checker = { enabled = false },

        performance = {
            rtp = {
                -- Oil replaces it, and two file explorers is one too many.
                disabled_plugins = { 'netrwPlugin', 'gzip' },
            },
        },

        -- Any plugin that needs rocks does not get any: the config's own
        -- dependencies are Mason packages, not Lua rocks.
        rocks = { enabled = false },

        ui = { border = 'rounded' },
    })
end

return M
