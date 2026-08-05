#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# Lua and Neovim configuration tools.
install_language() {
    language_bootstrap
    info 'Installing Lua tools'
    if module_enabled coding; then
        ensure_mason lua-language-server lua-language-server
        ensure_mason stylua stylua
    fi
    install_parsers lua
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
