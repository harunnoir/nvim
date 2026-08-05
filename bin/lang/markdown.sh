#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# Markdown language server, formatter, and parsers.
install_language() {
    language_bootstrap
    info 'Installing Markdown tools'
    if module_enabled coding; then
        need node
        need npm
        ensure_mason marksman marksman
        ensure_mason prettier prettier
    fi
    install_parsers markdown markdown_inline
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
