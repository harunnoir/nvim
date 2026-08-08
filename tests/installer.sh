#!/usr/bin/env bash
set -Eeuo pipefail

# Verify the core installer stays distro-agnostic and language tools remain opt-in.
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../bin/install.sh
source "$ROOT/bin/install.sh"

module_enabled terminal
module_enabled repl
module_enabled project

if grep -R --include='*.sh' -En '^[[:space:]]*(sudo|apt|apt-get|dnf|pacman|xbps-install)([[:space:]]|$)' "$ROOT/bin"; then
    printf 'installer contains a privileged or distro-specific command\n' >&2
    exit 1
fi

# Blink uses a tagged prebuilt matcher and compiles only when that download fails.
grep -Fq "version = '1.*'" "$ROOT/lua/modules/coding.lua"
grep -Fq "implementation = 'rust'" "$ROOT/lua/modules/coding.lua"
grep -Fq "libblink_cmp_fuzzy.*" "$ROOT/bin/install.sh"
grep -Fq 'cargo build --release --locked' "$ROOT/bin/install.sh"

# The core entrypoint must not install language profiles.
! grep -Eq 'run_language|enabled_languages|--lang|--school|--all' "$ROOT/bin/install.sh"
grep -Fq 'Language tools are installed separately' "$ROOT/bin/install.sh"

# Python keeps required editor tools separate from optional debugger and REPL tools.
grep -Fq 'ensure_uv_tool basedpyright-langserver basedpyright' "$ROOT/bin/lang/python.sh"
grep -Fq '# ensure_uv_tool ruff ruff' "$ROOT/bin/lang/python.sh"
grep -Fq 'ensure_uv_tool flake8 flake8' "$ROOT/bin/lang/python.sh"
grep -Fq 'ensure_uv_tool autopep8 autopep8' "$ROOT/bin/lang/python.sh"
grep -Fq 'ensure_uv_tool docformatter docformatter' "$ROOT/bin/lang/python.sh"
grep -Fq "Install optional Python debugging support" "$ROOT/bin/lang/python.sh"
grep -Fq "Install optional Python REPL tools" "$ROOT/bin/lang/python.sh"
grep -Fq -- '--minimal' "$ROOT/bin/lang/python.sh"
grep -Fq -- '--all' "$ROOT/bin/lang/python.sh"
grep -Fq 'ensure_uv_tool c_formatter_42 c-formatter-42' "$ROOT/bin/lang/c.sh"
grep -Fq 'ensure_uv_tool c_formatter_42 c-formatter-42' "$ROOT/bin/lang/cpp.sh"
! grep -Fq 'ensure_mason clang-format clang-format' "$ROOT/bin/lang/c.sh"
! grep -Fq 'ensure_mason clang-format clang-format' "$ROOT/bin/lang/cpp.sh"

# Exercise Python minimal/all modes without installing anything.
# shellcheck source=../bin/lang/python.sh
source "$ROOT/bin/lang/python.sh"
calls=()
language_bootstrap() { :; }
module_enabled() { [[ $1 == coding || $1 == debug || $1 == repl ]]; }
pick() { printf '/usr/bin/python3\n'; }
has() { [[ $1 == python || $1 == python3 ]]; }
ensure_uv_tool() { calls+=("$1:$2"); }
ensure_ptpython() { calls+=('ptpython+ptipython'); }
install_parsers() { calls+=("parser:$*"); }

install_language minimal
minimal=" ${calls[*]} "
[[ $minimal == *' basedpyright-langserver:basedpyright '* ]]
[[ $minimal == *' flake8:flake8 '* ]]
[[ $minimal != *' ruff:ruff '* ]]
[[ $minimal == *' autopep8:autopep8 '* ]]
[[ $minimal == *' docformatter:docformatter '* ]]
[[ $minimal == *' parser:python '* ]]
[[ $minimal != *' debugpy-adapter:debugpy '* ]]
[[ $minimal != *' ipython:ipython '* ]]

calls=()
install_language all
all=" ${calls[*]} "
[[ $all == *' debugpy-adapter:debugpy '* ]]
[[ $all == *' ipython:ipython '* ]]
[[ $all == *' ptpython+ptipython '* ]]

for script in "$ROOT"/bin/*.sh "$ROOT"/bin/lang/*.sh "$ROOT"/tests/*.sh; do
    [[ -x $script ]] || { printf '%s is not executable\n' "$script" >&2; exit 1; }
    bash -n "$script"
done

printf 'installer structure test passed\n'
