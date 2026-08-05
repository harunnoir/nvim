#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

ensure_uv() {
    if has uv; then
        printf '    reusing: uv\n'
        return
    fi

    info 'Installing uv for user-local Python tools'
    mkdir -p "$LOCAL_BIN"
    if has curl; then
        curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$LOCAL_BIN" UV_NO_MODIFY_PATH=1 sh
    else
        wget -qO- https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$LOCAL_BIN" UV_NO_MODIFY_PATH=1 sh
    fi
    hash -r
    need uv
}

ensure_uv_tool() {
    local command=$1 package=$2
    shift 2
    if has "$command"; then
        printf '    reusing: %s\n' "$command"
        return
    fi

    ensure_uv
    info "Installing Python tool: $package"
    UV_TOOL_BIN_DIR="$LOCAL_BIN" uv tool install --force "$package" "$@"
    hash -r
    has "$command" || die "$package did not provide $command"
}

# C language tools plus 42-school commands when that module is enabled.
install_language() {
    language_bootstrap
    info 'Installing C tools'
    pick cc gcc clang >/dev/null || die 'a C compiler is required for C support'
    if module_enabled coding; then
        ensure_mason clangd clangd
        ensure_mason clang-format clang-format
    fi
    if module_enabled debug; then
        ensure_mason codelldb codelldb
    fi
    if module_enabled school42; then
        ensure_uv_tool norminette norminette
        ensure_uv_tool c_formatter_42 c-formatter-42
    fi
    install_parsers c make
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
