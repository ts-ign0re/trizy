#!/bin/sh
# trizy installer: the kit in $TRIZY_HOME (default ~/.local/share/trizy), the `trizy` command in $TRIZY_BIN
# (default ~/.local/bin). No sudo; sh, git, curl and tar.
#
#   curl -fsSL https://raw.githubusercontent.com/ts-ign0re/trizy/main/install.sh | sh
#                                   the latest release (TRIZY_VERSION=v0.3.0 for a given one)
#   sh install.sh                   from a checkout: installs that checkout's committed HEAD
#   sh install.sh --uninstall       removes the command and the user install (projects keep .trizy/)
set -eu
REPO=ts-ign0re/trizy
KIT_HOME=${TRIZY_HOME:-$HOME/.local/share/trizy}
BIN_DIR=${TRIZY_BIN-$HOME/.local/bin} # set but empty (upgrade): leave the command as it is
if [ -n "${TRIZY_VERSION:-}" ]; then BASE=https://github.com/$REPO/releases/download/$TRIZY_VERSION
else BASE=https://github.com/$REPO/releases/latest/download; fi
BASE=${TRIZY_RELEASE_URL:-$BASE} # releases/latest/download, not api.github.com: the API allows 60 calls an hour per IP

die() { echo "trizy: $*" >&2; exit 1; }
if [ "${1:-}" = --uninstall ]; then
  rm -f "${BIN_DIR:-$HOME/.local/bin}/trizy"
  rm -rf "$KIT_HOME"
  echo "trizy: removed $BIN_DIR/trizy and $KIT_HOME (installed projects keep .trizy/)"
  exit 0
fi
command -v git >/dev/null 2>&1 || die "git is required"

here=''
case $0 in */install.sh | install.sh) here=$(cd "$(dirname "$0")" && pwd) ;; esac
tmp="$KIT_HOME.installing"
rm -rf "$tmp"
mkdir -p "$tmp"
if [ -n "$here" ] && [ -d "$here/.git" ] && [ -d "$here/template/.trizy" ]; then
  git -C "$here" archive HEAD | tar -x -C "$tmp"
else
  command -v curl >/dev/null 2>&1 || die "curl is required"
  curl -fsSL "$BASE/trizy.tar.gz" -o "$tmp/trizy.tar.gz" || die "cannot download $BASE/trizy.tar.gz"
  want=$(curl -fsSL "$BASE/trizy.tar.gz.sha256" | cut -d' ' -f1) || die "cannot download $BASE/trizy.tar.gz.sha256"
  if command -v sha256sum >/dev/null 2>&1; then got=$(sha256sum "$tmp/trizy.tar.gz" | cut -d' ' -f1)
  else got=$(shasum -a 256 "$tmp/trizy.tar.gz" | cut -d' ' -f1); fi
  [ -n "$want" ] && [ "$got" = "$want" ] || { rm -rf "$tmp"; die "checksum mismatch for $BASE/trizy.tar.gz"; }
  tar -xzf "$tmp/trizy.tar.gz" -C "$tmp" --strip-components 1 && rm -f "$tmp/trizy.tar.gz"
fi
[ -x "$tmp/template/.trizy/bin/trizy" ] || { rm -rf "$tmp"; die "not a trizy release"; }
rm -rf "$KIT_HOME"
mv "$tmp" "$KIT_HOME"

echo "trizy $(cat "$KIT_HOME/template/.trizy/VERSION") installed in $KIT_HOME"
[ -n "$BIN_DIR" ] || exit 0
mkdir -p "$BIN_DIR"
printf '#!/bin/sh\nexec "%s/bin/trizy" "$@"\n' "$KIT_HOME" >"$BIN_DIR/trizy.tmp"
chmod +x "$BIN_DIR/trizy.tmp"
mv "$BIN_DIR/trizy.tmp" "$BIN_DIR/trizy"
echo "command: $BIN_DIR/trizy"
case ":$PATH:" in
  *":$BIN_DIR:"*) echo "next: cd <your repository> && trizy init" ;;
  *) echo "add it to PATH (in ~/.zshrc or ~/.profile): export PATH=\"$BIN_DIR:\$PATH\"; then: trizy init" ;;
esac
