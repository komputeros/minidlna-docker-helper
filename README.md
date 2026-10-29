# Mint-DLNA

Serwer multimediów DLNA ([MiniDLNA](https://sourceforge.net/projects/minidlna/)) w Dockerze. Włączasz go ręcznie, kiedy jest potrzebny:

- jedno polecenie (albo jeden klik w menu) włącza lub wyłącza serwer,
- przy każdym starcie baza jest przyrostowo reindeksowana, więc widać pliki dodane i usunięte, gdy serwer był wyłączony,
- dopóki serwer działa, w trayu Cinnamona jest ikona z menu (logi, zatrzymanie).

## Wymagania

| Składnik | Pakiet (Linux Mint / Ubuntu) | Do czego |
|---|---|---|
| Docker Engine + Compose v2 | `docker-ce`, `docker-compose-plugin` | uruchamianie kontenera |
| Użytkownik w grupie `docker` | `sudo usermod -aG docker $USER` | docker bez sudo |
| Python 3 + GObject | `python3`, `python3-gi` | ikona w trayu |
| XApp (introspekcja) | `gir1.2-xapp-1.0` | ikona w trayu (Cinnamon) |
| libnotify | `libnotify-bin` | powiadomienia na pulpicie |
| Aplet „Xapp Status Applet” na panelu | domyślnie w Cinnamonie | wyświetlanie ikony |

Obraz kontenera: [`vladgh/minidlna:1.3.13`](https://hub.docker.com/r/vladgh/minidlna). Kontener działa w sieci hosta (`network_mode: host`), bo inaczej nie przejdzie wykrywanie SSDP/UPnP.

## Struktura repozytorium

```
bin/minidlna                     skrypt sterujący: start | stop | status | toggle
bin/minidlna-tray                ikona w trayu (Python, XApp.StatusIcon)
compose/compose.yaml             definicja usługi
compose/.env.example             szablon zmiennych (ścieżka mediów, UID/GID)
desktop/minidlna-toggle.desktop  szablon skrótu w menu (@BIN_DIR@ podmieniany przy instalacji)
install.sh                       wdrożenie
uninstall.sh                     usunięcie (opcjonalnie --purge)
```

## Wdrożenie

```bash
cd ~/src/minidlna
./install.sh
```

Skrypt sprawdza wymagania i kopiuje pliki tam, gdzie mają działać. Można go uruchamiać wielokrotnie, np. po każdej zmianie w repo. Istniejący plik `.env` zostaje nietknięty.

### Ścieżki po wdrożeniu

| Plik | Lokalizacja |
|---|---|
| compose | `~/docker/minidlna/compose.yaml` |
| zmienne lokalne | `~/docker/minidlna/.env` (poza repo, tworzony z `.env.example`) |
| skrypty | `~/.local/bin/minidlna`, `~/.local/bin/minidlna-tray` |
| skrót w menu | `~/.local/share/applications/minidlna-toggle.desktop` |
| baza i logi minidlna | wolumen Dockera `minidlna_cache` (w kontenerze `/minidlna`) |
| lock ikony | `$XDG_RUNTIME_DIR/minidlna-tray.lock` |
| media | `MEDIA_PATH` z `.env` (domyślnie `/media/havoc/swap`), w kontenerze `/media`, tylko do odczytu |

Ścieżka `~/docker/minidlna` jest wpisana na stałe w `bin/minidlna` oraz w obu skryptach instalacyjnych.

## Użycie

```bash
minidlna          # przełącz: działa → zatrzymaj, stoi → uruchom
minidlna start    # uruchom (+ powiadomienie + ikona w trayu)
minidlna stop     # zatrzymaj
minidlna status   # "DLNA działa" (kod 0) / "DLNA zatrzymane" (kod 3)
```

Można też kliknąć **Mint-DLNA** w menu. Wpis da się przypiąć do panelu albo podpiąć pod skrót klawiszowy z poleceniem `~/.local/bin/minidlna`.

Ikona w trayu pokazuje się po `minidlna start`. Kliknięcie otwiera menu z opcjami **Pokaż logi** i **Zatrzymaj DLNA**. Co 5 s ikona sprawdza stan kontenera i znika sama, gdy zostanie on zatrzymany w jakikolwiek sposób. Jeśli kontener wystartował z pominięciem skryptu, ikonę uruchamia się ręcznie: `minidlna-tray &`.

## Jak działa reindeksacja

Entrypoint obrazu obsługuje dwie zmienne:

- `FORCE_SCAN=true` (włączone na stałe w `compose.yaml`) przekazuje do `minidlnad` flagę `-r`. Przy każdym starcie robi przyrostowy rescan: dopisuje nowe pliki i usuwa nieistniejące.
- `FORCE_REBUILD=true` przekazuje flagę `-R`. Kasuje bazę i buduje ją od zera.

W trakcie pracy zmiany wyłapuje inotify (`MINIDLNA_INOTIFY=yes`).

Baza leży w nazwanym wolumenie, więc przetrwa też `docker compose down` i aktualizację obrazu.

## Rozwiązywanie problemów

**Baza się rozjechała (duplikaty, złe miniatury, brak plików).** Przebuduj ją od zera, a potem wróć do zwykłego trybu:

```bash
cd ~/docker/minidlna
FORCE_REBUILD=true docker compose up -d --force-recreate
# po zakończeniu skanowania:
docker compose up -d --force-recreate
```

Można też usunąć wolumen: `docker compose down -v`.

**Brak ikony w trayu.** Dodaj do panelu aplet *Xapp Status Applet* (prawy klik na panel → Aplety). Sprawdź też, czy działa proces: `pgrep -af minidlna-tray`.

**Serwer niewidoczny na TV.** Sprawdź logi (`docker logs dlna`) i to, czy zapora nie blokuje UDP 1900 (SSDP) oraz TCP 8200 (HTTP minidlna). Stan skanowania jest widoczny pod `http://localhost:8200`.

## Odinstalowanie

```bash
./uninstall.sh           # usuwa kontener, skrypty i skrót; zostawia ~/docker/minidlna i bazę
./uninstall.sh --purge   # usuwa także katalog compose i wolumen z bazą
```
