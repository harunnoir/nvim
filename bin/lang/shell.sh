#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# Shell language server, formatter, and parser.
install_language() {
    language_bootstrap
    info 'Installing shell tools'
    if module_enabled coding; then
        need node
        need npm
        ensure_mason bash-language-server bash-language-server
        ensure_mason shfmt shfmt
    fi
    install_parsers bash
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
