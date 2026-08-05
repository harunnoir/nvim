local M = {}

function M.install(name, force)
    assert(type(name) == 'string' and name:match('^[%w_.@-]+$'), 'invalid Mason package name')

    local registry = require('mason-registry')
    local finished = false
    local succeeded = false
    local failure

    local function done(ok, err)
        succeeded = ok == true
        failure = err
        finished = true
    end

    local function install_package(package)
        package:install({}, function(installed, install_error)
            done(installed and package:is_installed(), install_error)
        end)
    end

    registry.refresh(function(refreshed, refresh_error)
        if not refreshed then
            done(false, refresh_error or 'registry refresh failed')
            return
        end

        local ok, package = pcall(registry.get_package, name)
        if not ok then
            done(false, package)
            return
        end

        if package:is_installed() then
            if not force then
                done(true)
                return
            end

            package:uninstall({}, function(uninstalled, uninstall_error)
                if not uninstalled then
                    done(false, uninstall_error or 'uninstall failed')
                    return
                end
                install_package(package)
            end)
            return
        end

        install_package(package)
    end)

    if not vim.wait(300000, function() return finished end, 100) then
        error('Mason installation timed out: ' .. name)
    end
    if not succeeded then
        error(('Mason failed to install %s: %s'):format(name, tostring(failure or 'unknown error')))
    end
end

return M
