#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
# Reuse the small installer helpers without running the core installer again.
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

confirm() {
    local prompt=$1 reply
    [[ -t 0 ]] || return 1
    read -r -p "$prompt [y/N] " reply
    [[ $reply == [yY] || $reply == [yY][eE][sS] ]]
}

ensure_ptpython() {
    if has ptpython && has ptipython; then
        printf '    reusing: ptpython and ptipython\n'
        return
    fi
    ensure_uv
    info 'Installing ptpython with IPython support'
    UV_TOOL_BIN_DIR="$LOCAL_BIN" uv tool install --force --with ipython ptpython
    hash -r
    need ptpython
    need ptipython
}

install_language() {
    local optional_mode=${1:-prompt}
    local python

    language_bootstrap
    info 'Installing required Python editor tools'
    python=$(pick python3 python) || die 'Python is required for the Python profile'
    if ! has python; then
        mkdir -p "$LOCAL_BIN"
        ln -sfn "$python" "$LOCAL_BIN/python"
        hash -r
    fi

    ensure_uv_tool basedpyright-langserver basedpyright
    # ensure_uv_tool ruff ruff # Flake8 is the active Python linter.
    ensure_uv_tool flake8 flake8
    ensure_uv_tool autopep8 autopep8
    ensure_uv_tool docformatter docformatter
    install_parsers python

    if [[ $optional_mode == all ]] || { [[ $optional_mode == prompt ]] && confirm 'Install optional Python debugging support (debugpy)?'; }; then
        ensure_uv_tool debugpy-adapter debugpy
    fi

    if [[ $optional_mode == all ]] || { [[ $optional_mode == prompt ]] && confirm 'Install optional Python REPL tools (IPython, ptpython, ptipython)?'; }; then
        ensure_uv_tool ipython ipython
        ensure_ptpython
    fi

    if [[ $optional_mode == prompt && ! -t 0 ]]; then
        warn 'No terminal input; optional Python tools were skipped (use --all to install them)'
    fi
}

usage() {
    cat <<'HELP'
Usage: ./bin/lang/python.sh [OPTION]

Installs required Python editor tools, then optionally installs debugging and
interactive REPL tools.

  --minimal       install basedpyright, Flake8, formatters, and the Python parser
  --all           also install debugpy, IPython, ptpython, and ptipython
  --help          show this help

With no option, optional groups are confirmed interactively.
HELP
}

main() {
    case ${1:-prompt} in
        prompt) install_language prompt ;;
        --minimal) install_language minimal ;;
        --all | --yes) install_language all ;;
        --help | -h) usage ;;
        *) die "unknown option: $1" ;;
    esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
