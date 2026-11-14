#!/bin/sh
# Install vee for the current user. Works from a checkout or as a standalone file.
set -eu

usage()
{
  cat <<'EOF'
Usage: sh install.sh [--prefix DIRECTORY]

Install all six vee commands into DIRECTORY/bin.
Default: $HOME/.local/bin. No root access or Perl required.

From a checkout, use the adjacent bin/ files. A standalone copy downloads
commands from GitHub using curl or wget. VEE_REF may select another Git ref;
the default is a pinned, tested 2.0 commit. Re-running replaces installed commands.
EOF
}

fail() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }

PREFIX=
while [ "$#" -gt 0 ]; do
  case $1 in
    --prefix)
      [ "$#" -ge 2 ] || fail '--prefix requires a directory'
      [ -n "$2" ] || fail '--prefix requires a nonempty directory'
      PREFIX=$2
      shift 2
      ;;
    -h|--help) usage; exit 0;;
    *) fail "unknown argument: $1";;
  esac
done
if [ -z "$PREFIX" ]; then
  [ -n "${HOME:-}" ] || fail 'HOME is unset; supply --prefix DIRECTORY'
  PREFIX=$HOME/.local
fi
# Anchor relative prefixes before invoking utilities; leading hyphens are safe.
case $PREFIX in /*) ;; *) PREFIX=$PWD/$PREFIX;; esac
BINDIR=$PREFIX/bin
COMMANDS='vee veels veecat veefind vee-rebuild vee-publish'
REF=${VEE_REF:-fb5cf4443540a4377048889280396c8270c83506}
case $REF in ''|*[!a-zA-Z0-9._/-]*) fail 'VEE_REF must be a GitHub branch, tag, or commit';; esac

SOURCE=
# $0 is not a source filename when the script is piped into sh.
if [ -f "$0" ]; then
  SCRIPT_DIR=$(CDPATH='' cd -P "$(dirname "$0")" && pwd)
  if [ -f "$SCRIPT_DIR/bin/vee" ]; then SOURCE=$SCRIPT_DIR/bin; fi
fi
if [ -z "$SOURCE" ]; then
  if command -v curl >/dev/null 2>&1; then
    FETCH=curl
  elif command -v wget >/dev/null 2>&1; then
    FETCH=wget
  else
    fail 'standalone installation needs curl or wget; alternatively download the repository archive'
  fi
fi

# Validate all destinations before changing any installed command.
mkdir -p "$BINDIR" || fail "cannot create $BINDIR"
for command_name in $COMMANDS; do
  target=$BINDIR/$command_name
  [ ! -d "$target" ] && [ ! -L "$target" ] || fail "refusing directory or symlink: $target"
done
STAGE=$BINDIR/.vee-install.$$
(umask 077; mkdir "$STAGE") || fail "cannot create staging directory in $BINDIR"
trap 'rm -rf "$STAGE"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Fetch and validate everything before replacing any installed command.
for command_name in $COMMANDS; do
  if [ -n "$SOURCE" ]; then
    cp "$SOURCE/$command_name" "$STAGE/$command_name"
  else
    URL=https://raw.githubusercontent.com/oodler577/vee/$REF/bin/$command_name
    case $FETCH in
      curl) curl -fLsS "$URL" -o "$STAGE/$command_name";;
      wget) wget -q -O "$STAGE/$command_name" "$URL";;
    esac
  fi
  [ "$(head -n 1 "$STAGE/$command_name")" = '#!/bin/sh' ] || fail "invalid shell script: $command_name"
  sh -n "$STAGE/$command_name" || fail "shell syntax error in $command_name"
  chmod 755 "$STAGE/$command_name"
done
for command_name in $COMMANDS; do
  mv "$STAGE/$command_name" "$BINDIR/$command_name"
done
printf 'Installed vee and its companion commands in %s\n' "$BINDIR"
case :${PATH:-}: in
  *:"$BINDIR":*) ;;
  *)
    # Print a shell-quoted PATH command, even when the prefix contains quotes.
    QUOTED_BINDIR=$(printf '%s' "$BINDIR" | sed "s/'/'\\\\''/g")
    printf "Add this to your shell startup file, or run it now:\n  export PATH='%s':\"\$PATH\"\n" "$QUOTED_BINDIR"
    ;;
esac
