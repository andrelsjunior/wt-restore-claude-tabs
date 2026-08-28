#!/usr/bin/env bash
# Symlink wt-restore-claude-tabs into your PATH.
# Usage: ./install.sh          installs into ~/.local/bin
#        PREFIX=/usr/local ./install.sh

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="${PREFIX}/bin"
TARGET="${BIN_DIR}/wt-restore-claude-tabs"

mkdir -p "${BIN_DIR}"
ln -sf "${SOURCE_DIR}/bin/wt-restore-claude-tabs" "${TARGET}"
chmod +x "${SOURCE_DIR}/bin/wt-restore-claude-tabs"

echo "installed: ${TARGET} -> ${SOURCE_DIR}/bin/wt-restore-claude-tabs"

case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *) echo "warning: ${BIN_DIR} is not in your PATH" >&2 ;;
esac

echo
echo "Try it:  wt-restore-claude-tabs --help"
echo "Alias:   echo 'alias rt=\"wt-restore-claude-tabs\"' >> ~/.zshrc"
