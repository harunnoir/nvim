#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# shellcheck source=../install.sh
source "$ROOT/bin/install.sh"

# Rustup owns compiler components; Mason supplies editor-facing binaries.
install_language() {
    language_bootstrap
    info 'Installing Rust tools'
    need rustc
    need cargo
    if module_enabled coding; then
        ensure_mason rust-analyzer rust-analyzer
        has rustfmt || warn 'rustfmt is missing; install it with rustup component add rustfmt'
        has clippy || warn 'clippy is missing; install it with rustup component add clippy'
    fi
    if module_enabled debug; then
        ensure_mason codelldb codelldb
    fi
    install_parsers rust toml
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    install_language "$@"
fi
