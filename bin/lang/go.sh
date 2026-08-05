#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# Go runtime must exist; editor-facing tools remain user-local through Mason.
install_language() {
    language_bootstrap
    info 'Installing Go tools'
    need go
    if module_enabled coding; then
        ensure_mason gopls gopls
        ensure_mason gofumpt gofumpt
        ensure_mason goimports goimports
    fi
    if module_enabled debug; then
        ensure_mason delve dlv
    fi
    install_parsers go gomod gosum gowork
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
