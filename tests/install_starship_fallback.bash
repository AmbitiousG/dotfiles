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

write_mock apt-get '
echo "apt-get $*" >>"$log"
exit 0
'

write_mock apt-cache '
echo "apt-cache $*" >>"$log"
if [ "${1:-}" = "show" ] && [ "${2:-}" = "starship" ]; then
  exit 1
fi
exit 0
'

write_mock sudo '
echo "sudo $*" >>"$log"
exec "$@"
'

write_mock stow '
echo "stow $*" >>"$log"
exit 0
'

write_mock curl '
echo "curl $*" >>"$log"
printf "%s\n" "#!/usr/bin/env bash"
printf "%s\n" "echo starship-installer \"\$@\" >>\"$log\""
'

PATH="$mockbin:/usr/bin:/bin" HOME="$home" "$repo_root/install.sh" >/tmp/install-output.txt

if ! grep -q 'curl -fsSL https://starship.rs/install.sh' "$log"; then
  echo "expected install.sh to download the official Starship installer" >&2
  cat "$log" >&2
  exit 1
fi

if ! grep -q 'starship-installer -y' "$log"; then
  echo "expected install.sh to run the Starship installer with -y" >&2
  cat "$log" >&2
  exit 1
fi
