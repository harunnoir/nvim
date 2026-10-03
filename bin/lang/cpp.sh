#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# Reuse the Python-native formatter installer from the C profile.
# shellcheck source=./c.sh
source "$ROOT/bin/lang/c.sh"

# C++ shares Clang and LLDB tooling with C but keeps an independent profile.
install_language() {
    language_bootstrap
    info 'Installing C++ tools'
    pick c++ g++ clang++ >/dev/null || die 'a C++ compiler is required for C++ support'
    ensure_mason clangd clangd
    ensure_uv_tool c_formatter_42 c-formatter-42
    ensure_mason codelldb codelldb
    install_parsers cpp
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
