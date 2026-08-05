#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# C++ shares Clang and LLDB tooling with C but keeps an independent profile.
install_language() {
    language_bootstrap
    info 'Installing C++ tools'
    pick c++ g++ clang++ >/dev/null || die 'a C++ compiler is required for C++ support'
    if module_enabled coding; then
        ensure_mason clangd clangd
        ensure_mason clang-format clang-format
    fi
    if module_enabled debug; then
        ensure_mason codelldb codelldb
    fi
    install_parsers cpp
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
