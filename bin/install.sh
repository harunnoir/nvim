#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
MODULES_FILE=${ENOUGH_MODULES_FILE:-"$ROOT/lua/modules/init.lua"}
LOCAL_BIN=${XDG_BIN_HOME:-"$HOME/.local/bin"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
APP_NAME=${NVIM_APPNAME:-$(basename "$ROOT")}
MASON_HOME="$DATA_HOME/$APP_NAME/mason"
MASON_BIN="$MASON_HOME/bin"
NVIM_VERSION=${NVIM_VERSION:-0.12.4}
NVIM=${NVIM:-nvim}
MASON_READY=0

export PATH="$MASON_BIN:$LOCAL_BIN:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

info() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }
need() { has "$1" || die "$1 is required"; }

pick() {
    local command
    for command in "$@"; do
        if has "$command"; then
            command -v "$command"
            return 0
        fi
    done
    return 1
}

module_enabled() {
    grep -Eq "^[[:space:]]*$1[[:space:]]*=[[:space:]]*true[[:space:]]*,?" "$MODULES_FILE"
}

version_ge() {
    local current=$1 required=$2
    [[ $(printf '%s\n%s\n' "$required" "$current" | sort -V | head -n1) == "$required" ]]
}

download() {
    local url=$1 output=$2
    if has curl; then
        curl -fL --retry 3 -o "$output" "$url"
    elif has wget; then
        wget -O "$output" "$url"
    else
        die 'curl or wget is required'
    fi
}

install_neovim() {
    local current='' arch asset tmp destination extracted
    if has "$NVIM"; then
        current=$($NVIM --version | sed -n '1s/^NVIM v//p')
        if [[ -n $current ]] && version_ge "$current" '0.12.0'; then
            info "Reusing Neovim $current"
            return
        fi
        warn "Neovim ${current:-unknown} is older than 0.12"
    fi

    [[ $(uname -s) == Linux ]] || die 'automatic Neovim installation currently supports Linux only'
    case $(uname -m) in
        x86_64) arch=x86_64 ;;
        aarch64 | arm64) arch=arm64 ;;
        *) die "unsupported CPU architecture: $(uname -m)" ;;
    esac

    need tar
    tmp=$(mktemp -d)
    asset="nvim-linux-$arch"
    destination="$DATA_HOME/enough-nvim/neovim/$NVIM_VERSION"
    info "Installing Neovim $NVIM_VERSION in $destination"
    download "https://github.com/neovim/neovim-releases/releases/download/v$NVIM_VERSION/$asset.tar.gz" "$tmp/nvim.tar.gz"
    tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
    extracted="$tmp/$asset"
    [[ -x $extracted/bin/nvim ]] || die 'downloaded Neovim archive is invalid'
    mkdir -p "$(dirname "$destination")" "$LOCAL_BIN"
    rm -rf "$destination"
    mv "$extracted" "$destination"
    ln -sfn "$destination/bin/nvim" "$LOCAL_BIN/nvim"
    NVIM="$LOCAL_BIN/nvim"
    hash -r
    rm -rf "$tmp"
}

run_nvim() {
    (cd "$ROOT" && XDG_CONFIG_HOME=$(dirname "$ROOT") NVIM_APPNAME="$APP_NAME" "$NVIM" --headless "$@")
}

check_bootstrap() {
    need git
    pick curl wget >/dev/null || die 'curl or wget is required'
    need tar
    need gzip
    if module_enabled navigation || module_enabled editing || module_enabled coding \
        || module_enabled debug || module_enabled git; then
        need unzip
        tar --version 2>/dev/null | grep -q 'GNU tar' || die 'Mason requires GNU tar'
    fi
}

language_bootstrap() {
    has "$NVIM" || die 'Neovim is missing; run ./bin/install.sh first'
    check_bootstrap
}

sync_plugins() {
    info 'Synchronizing Neovim plugins'
    run_nvim '+Lazy! sync' +qa
}

ensure_blink_rust() {
    module_enabled coding || return

    local plugin_dir="$DATA_HOME/$APP_NAME/lazy/blink.cmp"
    local release_dir="$plugin_dir/target/release"
    local library

    # Tagged releases download an optimized Rust matcher; compile only as fallback.
    if ! run_nvim '+lua require("blink.cmp")' +qa; then
        warn 'Blink could not load its prebuilt Rust matcher; checking the build fallback'
    fi
    library=$(find "$release_dir" -maxdepth 1 -type f -name 'libblink_cmp_fuzzy.*' -print -quit 2>/dev/null || true)
    if [[ -n $library ]]; then
        printf '    blink matcher: %s\n' "$library"
        return
    fi

    has cargo || die 'Blink Rust matcher download failed; install Rust/cargo and rerun the installer'
    info 'Building the Blink Rust matcher from source'
    (cd "$plugin_dir" && cargo build --release --locked)
    library=$(find "$release_dir" -maxdepth 1 -type f -name 'libblink_cmp_fuzzy.*' -print -quit 2>/dev/null || true)
    [[ -n $library ]] || die 'Blink Rust matcher build did not produce a shared library'
}

ensure_mason_ready() {
    [[ $MASON_READY == 1 ]] && return
    [[ -d "$DATA_HOME/$APP_NAME/lazy/mason.nvim" ]] || sync_plugins
    [[ -d "$DATA_HOME/$APP_NAME/lazy/mason.nvim" ]] \
        || die 'Mason is unavailable; enable the coding or debug module'
    MASON_READY=1
}

# Mason keeps editor-facing binaries user-local and avoids distro-specific commands.
ensure_mason() {
    local package=$1 command
    shift
    local missing=0
    for command in "$@"; do
        if has "$command"; then
            printf '    reusing: %s\n' "$command"
        else
            missing=1
        fi
    done
    [[ $missing == 0 ]] && return

    ensure_mason_ready
    info "Installing Mason package: $package"
    ENOUGH_MASON_PACKAGE="$package" ENOUGH_MASON_FORCE=1 \
        ENOUGH_MASON_SCRIPT="$ROOT/bin/mason_install.lua" run_nvim \
        "+lua dofile(vim.env.ENOUGH_MASON_SCRIPT).install(vim.env.ENOUGH_MASON_PACKAGE, true)" +qa
    hash -r
    for command in "$@"; do
        has "$command" || die "$command was not installed by Mason package $package"
    done
}

install_parsers() {
    module_enabled editing || return
    local parser table='{'
    for parser in "$@"; do
        table+="'$parser',"
    done
    table+='}'
    info "Installing Tree-sitter parsers: $*"
    run_nvim "+lua require('nvim-treesitter').install($table):wait(300000)" +qa
}

install_core() {
    check_bootstrap
    install_neovim
    sync_plugins
    ensure_blink_rust

    if module_enabled navigation; then
        ensure_mason ripgrep rg
        ensure_mason fd fd
        if ! has trash-put; then
            warn 'trash-put is optional; Oil will use permanent deletion until trash-cli is installed'
        fi
    fi
    if module_enabled editing; then
        pick cc gcc clang >/dev/null || die 'a C compiler is required for Tree-sitter parsers'
        ensure_mason tree-sitter-cli tree-sitter
    fi
    if module_enabled git; then
        ensure_mason lazygit lazygit
    fi
}

check_installation() {
    local failed=0

    check_command() {
        local label=$1 command=$2 required=${3:-1}
        if has "$command"; then
            printf '  ✓ %-22s %s\n' "$label" "$(command -v "$command")"
        elif [[ $required == 1 ]]; then
            printf '  ✗ %s\n' "$label"
            failed=1
        else
            printf '  - %-22s optional\n' "$label"
        fi
    }

    check_command Neovim "$NVIM"
    check_command Git git
    if module_enabled coding; then
        local blink_library
        blink_library=$(find "$DATA_HOME/$APP_NAME/lazy/blink.cmp/target/release" \
            -maxdepth 1 -type f -name 'libblink_cmp_fuzzy.*' -print -quit 2>/dev/null || true)
        if [[ -n $blink_library ]]; then
            printf '  ✓ %-22s %s\n' 'Blink Rust matcher' "$blink_library"
        else
            printf '  ✗ Blink Rust matcher\n'
            failed=1
        fi
    fi
    if module_enabled navigation; then
        check_command ripgrep rg
        check_command fd fd
        check_command trash-put trash-put 0
    fi
    if module_enabled editing; then
        check_command tree-sitter tree-sitter
        pick cc gcc clang >/dev/null || {
            printf '  ✗ C compiler\n'
            failed=1
        }
    fi
    if module_enabled git; then
        check_command Lazygit lazygit
    fi
    return "$failed"
}

usage() {
    cat <<'HELP'
Usage: ./bin/install.sh [OPTION]

Installs Neovim, plugins, and plugin runtime requirements only.
Language tools are installed separately through bin/lang/*.sh.
Everything stays user-local; sudo and distro package managers are never used.

  --check         report core commands without changing anything
  --test          run the small startup and installer tests
  --help          show this help

With no option, the core editor setup is installed.
HELP
}

main() {
    case ${1:-install} in
        --help | -h)
            usage
            return
            ;;
        --check)
            check_installation
            return
            ;;
        --test)
            "$ROOT/tests/installer.sh"
            "$ROOT/tests/startup.sh"
            return
            ;;
        install | --core)
            install_core
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac

    info 'Core installation complete'
    printf 'Add %s to PATH if it is not already there.\n' "$LOCAL_BIN"
    printf 'Run a script under bin/lang/ for language tooling.\n'
    printf 'Run :ConfigHealth inside Neovim to inspect the setup.\n'
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
