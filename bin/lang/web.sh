#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# JavaScript and TypeScript runtime plus editor-facing web tools.
install_language() {
    language_bootstrap
    info 'Installing web tools'
    need node
    need npm
    if module_enabled coding; then
        ensure_mason typescript-language-server typescript-language-server
        ensure_mason eslint-lsp vscode-eslint-language-server
        ensure_mason html-lsp vscode-html-language-server
        ensure_mason css-lsp vscode-css-language-server
        ensure_mason json-lsp vscode-json-language-server
        ensure_mason prettier prettier
    fi
    install_parsers javascript javascriptreact typescript tsx html css json jsonc
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
