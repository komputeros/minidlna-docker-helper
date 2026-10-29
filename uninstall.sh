#!/usr/bin/env bash
# Usuwa wdrozone pliki. Z --purge usuwa tez katalog compose i wolumen z baza.
set -euo pipefail

COMPOSE_DIR="$HOME/docker/minidlna"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

if [[ -f "$COMPOSE_DIR/compose.yaml" ]]; then
  if [[ "${1:-}" == "--purge" ]]; then
    docker compose -f "$COMPOSE_DIR/compose.yaml" down -v
  else
    docker compose -f "$COMPOSE_DIR/compose.yaml" down
  fi
fi

pkill -f "$BIN_DIR/minidlna-tray" 2>/dev/null || true
rm -f "$BIN_DIR/minidlna" "$BIN_DIR/minidlna-tray" "$APP_DIR/minidlna-toggle.desktop"
update-desktop-database "$APP_DIR" 2>/dev/null || true

if [[ "${1:-}" == "--purge" ]]; then
  rm -rf "$COMPOSE_DIR"
  echo "Usunieto wszystko (lacznie z baza i $COMPOSE_DIR)"
else
  echo "Usunieto skrypty i skrot. Pozostawiono $COMPOSE_DIR i wolumen z baza (uzyj --purge, aby je usunac)"
fi
