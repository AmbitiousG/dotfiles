#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/bin:/bin:$PATH"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mockbin="$tmpdir/bin"
log="$tmpdir/calls.log"
home="$tmpdir/home"
mkdir -p "$mockbin" "$home"
: >"$log"

write_mock() {
  local name="$1"
  local body="$2"
  local path="$mockbin/$name"

  {
    printf '#!/usr/bin/env bash\n'
    printf 'set -euo pipefail\n'
    printf 'log=%q\n' "$log"
    printf '%s\n' "$body"
  } >"$path"
  chmod +x "$path"
}

write_mock id '
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
exit 1
'

write_mock stow '
echo "stow $*" >>"$log"
exit 0
'

write_mock grep '
if [ "${*: -1}" = "/etc/shells" ]; then
  exit 0
fi
exec /usr/bin/grep "$@"
'

write_mock sudo '
echo "sudo $*" >>"$log"
if [ "${1:-}" = "-n" ] && [ "${2:-}" = "true" ]; then
  exit 0
fi
if [ "${1:-}" = "-n" ]; then
  shift
fi
if [ "${1:-}" = "usermod" ]; then
  exit 0
fi
exec "$@"
'

write_mock chsh '
echo "chsh $*" >>"$log"
exit 0
'

write_mock zsh '
exit 0
'

PATH="$mockbin:/usr/bin:/bin" HOME="$home" USER="gy" "$repo_root/install.sh" --no-packages --chsh >/tmp/install-chsh-output.txt

if ! /usr/bin/grep -q 'sudo -n true' "$log"; then
  echo "expected install.sh to check sudo without prompting" >&2
  cat "$log" >&2
  exit 1
fi

if ! /usr/bin/grep -q "sudo -n usermod -s $mockbin/zsh gy" "$log"; then
  echo "expected install.sh to change the shell with non-interactive sudo usermod" >&2
  cat "$log" >&2
  exit 1
fi

if /usr/bin/grep -q '^chsh ' "$log"; then
  echo "expected install.sh not to call chsh in sudo-capable non-root installs" >&2
  cat "$log" >&2
  exit 1
fi
