#!/usr/bin/env bash
# Wdraza projekt do katalogow uzytkownika. Mozna uruchamiac wielokrotnie.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_DIR="$HOME/docker/minidlna"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

echo "=== Sprawdzanie wymagan"
missing=0
for cmd in docker python3 notify-send; do
  command -v "$cmd" >/dev/null || { echo "Brak: $cmd" >&2; missing=1; }
done
docker compose version >/dev/null 2>&1 || { echo "Brak: docker compose (plugin v2)" >&2; missing=1; }
python3 -c "import gi; gi.require_version('Gtk','3.0'); gi.require_version('XApp','1.0'); from gi.repository import Gtk, XApp" 2>/dev/null \
  || { echo "Brak: python3-gi / gir1.2-xapp-1.0 (ikona w trayu)" >&2; missing=1; }
[[ $missing -eq 0 ]] || { echo "Doinstaluj brakujace pakiety (patrz README.md)" >&2; exit 1; }

echo "=== Compose -> $COMPOSE_DIR"
mkdir -p "$COMPOSE_DIR"
install -m 644 "$SRC/compose/compose.yaml" "$COMPOSE_DIR/compose.yaml"
if [[ -f "$COMPOSE_DIR/.env" ]]; then
  echo "    .env juz istnieje – pozostawiony bez zmian"
else
  sed -e "s/^PUID=.*/PUID=$(id -u)/" -e "s/^PGID=.*/PGID=$(id -g)/" \
    "$SRC/compose/.env.example" > "$COMPOSE_DIR/.env"
  echo "    utworzono .env – sprawdz MEDIA_PATH"
fi

echo "=== Skrypty -> $BIN_DIR"
mkdir -p "$BIN_DIR"
install -m 755 "$SRC/bin/minidlna" "$SRC/bin/minidlna-tray" "$BIN_DIR/"

echo "=== Skrot w menu -> $APP_DIR"
mkdir -p "$APP_DIR"
sed "s|@BIN_DIR@|$BIN_DIR|g" "$SRC/desktop/minidlna-toggle.desktop" > "$APP_DIR/minidlna-toggle.desktop"
update-desktop-database "$APP_DIR" 2>/dev/null || true

echo "=== Gotowe. Uzycie: minidlna [start|stop|status|toggle]"
