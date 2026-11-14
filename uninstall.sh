#!/bin/sh
# Remove only the six commands installed by install.sh. Keep user data intact.
set -eu

usage()
{
  cat <<'EOF'
Usage: sh uninstall.sh [--prefix DIRECTORY] [--dry-run]

Remove vee, veels, veecat, veefind, vee-rebuild, and vee-publish from
DIRECTORY/bin. Default: $HOME/.local/bin, matching install.sh.

--dry-run lists the files that would be removed without changing anything.
Missing commands are ignored. Directories, symlinks, and special files at
command paths are refused before removing anything. No root access required
for your own installation. Blogs, configuration, PATH settings, and installation
directories are left in place. No network access or Perl is required.
EOF
}

fail() { printf 'uninstall.sh: %s\n' "$*" >&2; exit 1; }
PREFIX=
DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case $1 in
    --prefix)
      [ "$#" -ge 2 ] || fail '--prefix requires a directory'
      [ -n "$2" ] || fail '--prefix requires a nonempty directory'
      PREFIX=$2
      shift 2
      ;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) fail "unknown argument: $1";;
  esac
done
if [ -z "$PREFIX" ]; then
  [ -n "${HOME:-}" ] || fail 'HOME is unset; supply --prefix DIRECTORY'
  PREFIX=$HOME/.local
fi
case $PREFIX in /*) ;; *) PREFIX=$PWD/$PREFIX;; esac
BINDIR=$PREFIX/bin
COMMANDS='vee veels veecat veefind vee-rebuild vee-publish'

# Match the installer's destination policy and check every path before deleting.
COUNT=0
for command_name in $COMMANDS; do
  target=$BINDIR/$command_name
  if [ -L "$target" ] || { [ -e "$target" ] && [ ! -f "$target" ]; }; then
    fail "refusing non-regular file or symlink: $target"
  fi
  if [ -f "$target" ]; then COUNT=$((COUNT + 1)); fi
done
if [ "$COUNT" -eq 0 ]; then
  printf 'No vee commands found in %s\n' "$BINDIR"
  exit 0
fi
if [ "$DRY_RUN" = 0 ]; then
  [ -w "$BINDIR" ] && [ -x "$BINDIR" ] || fail "cannot remove commands from $BINDIR"
fi
for command_name in $COMMANDS; do
  target=$BINDIR/$command_name
  if [ -f "$target" ]; then
    if [ "$DRY_RUN" = 1 ]; then
      printf 'Would remove %s\n' "$target"
    else
      rm -f "$target"
      printf 'Removed %s\n' "$target"
    fi
  fi
done
if [ "$DRY_RUN" = 0 ]; then
  printf 'Uninstalled %s command(s). Blogs, configuration, and other files were preserved.\n' "$COUNT"
fi
