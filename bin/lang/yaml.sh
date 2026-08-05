#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# YAML language server, formatter, and parser.
install_language() {
    language_bootstrap
    info 'Installing YAML tools'
    if module_enabled coding; then
        need node
        need npm
        ensure_mason yaml-language-server yaml-language-server
        ensure_mason prettier prettier
    fi
    install_parsers yaml
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
