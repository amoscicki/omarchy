# Omarchy Run Script - Instalacja na istniejącym Arch Linux

Ten skrypt (`run.sh`) pozwala zainstalować wszystkie paczki i konfiguracje Omarchy na **już zainstalowanym systemie Arch Linux**, niezależnie od systemu plików (działa na ext4, Btrfs, itd.).

## Co robi ten skrypt?

Skrypt `run.sh` wykonuje **większość** kroków instalacyjnych Omarchy, ale **pomija instalację samego systemu**:

### ✅ CO ZOSTANIE ZAINSTALOWANE:

1. **Wszystkie paczki Omarchy** (~138 pakietów):
   - Hyprland (kompozytor Wayland)
   - Waybar, Rofi/Walker (menu, statusbar)
   - Kitty, Alacritty (terminale)
   - Docker, Git, Python, Node.js (narzędzia deweloperskie)
   - Firefox, Chromium (przeglądarki)
   - MPV, KDEnlive (multimedia)
   - SDDM (display manager)
   - Plymouth (boot splash)
   - Czcionki, ikony, motywy

2. **Wszystkie konfiguracje** skopiowane do `~/.config/`:
   - Hyprland, Waybar, Kitty, Alacritty
   - Git, GPG, Docker
   - Bashrc, motywy, itp.

3. **Webapps** (skróty do aplikacji webowych):
   - HEY, Basecamp, WhatsApp, YouTube, GitHub, ChatGPT, Discord, Zoom, itd.

4. **Konfiguracje sprzętowe**:
   - Sieć, Bluetooth, drukarka
   - Poprawki dla NVIDIA, Apple hardware, Surface, itp.

5. **First-run setup** (uruchomi się po restarcie):
   - Firewall (UFW)
   - DNS resolver
   - Motywy GNOME
   - WiFi setup
   - Monitorowanie baterii (dla laptopów)

### ⚠️ CO ZOSTANIE POMINIĘTE:

1. **Bootloader (Limine)** - Skrypt nie modyfikuje bootloadera
   - Twój obecny bootloader (GRUB, systemd-boot, etc.) pozostanie niezmieniony
   - Nie będzie Limine, chyba że go już masz

2. **Snapshoty Btrfs** - Jeśli masz ext4
   - Snapper i limine-snapper-sync nie zostaną skonfigurowane
   - To normalne - te narzędzia wymagają Btrfs

3. **Instalacja systemu** - Oczywiste, system już jest zainstalowany :)

## Wymagania

- **Arch Linux** (vanilla, nie CachyOS/Manjaro/EndeavourOS)
- **x86_64** (procesor 64-bitowy)
- **Konto użytkownika z sudo**
- **Dostęp do internetu** (do instalacji pakietów)
- **~10GB wolnego miejsca** (dla wszystkich pakietów)

### Zalecane (ale nie wymagane):

- Świeży system bez GNOME/KDE
- Secure Boot wyłączony (jeśli będziesz używał Plymouth)

## Jak użyć?

### 1. Sklonuj repo (jeśli jeszcze nie masz):

```bash
cd ~
git clone https://github.com/basecamp/omarchy.git
cd omarchy
```

### 2. Uruchom skrypt:

```bash
./run.sh
```

Skrypt będzie:
- Zadawał pytania, jeśli wykryje potencjalne problemy
- Pokazywał postęp instalacji
- Logował wszystko do `/var/log/omarchy-install.log`

### 3. Po zakończeniu - restart:

```bash
sudo reboot
```

### 4. Po restarcie:

1. **Wybierz SDDM** jako display manager (jeśli system zapyta)
2. **Zaloguj się** - Hyprland uruchomi się automatycznie
3. **First-run setup** wykona się automatycznie przy pierwszym logowaniu:
   - Skonfiguruje firewall
   - Ustawi DNS
   - Zastosuje motywy
   - Pokaże welcome screen z skrótami klawiszowymi

## Co jeśli coś pójdzie nie tak?

### Skrypt się zatrzymał:

1. Sprawdź log: `cat /var/log/omarchy-install.log`
2. Zobacz ostatnie błędy: `tail -50 /var/log/omarchy-install.log`
3. Możesz uruchomić skrypt ponownie - jest częściowo idempotentny

### Nie chcę SDDM/Plymouth:

Edytuj `run.sh` i zakomentuj (#) linie:
```bash
run_logged "$OMARCHY_INSTALL/login/plymouth.sh"
run_logged "$OMARCHY_INSTALL/login/sddm.sh"
```

### Chcę tylko paczki, bez konfiguracji:

Edytuj `run.sh` i zakomentuj sekcję:
```bash
# source "$OMARCHY_INSTALL/config/all.sh"
```

### Chcę tylko konfiguracje, bez paczek:

Edytuj `run.sh` i zakomentuj sekcję:
```bash
# source "$OMARCHY_INSTALL/packaging/all.sh"
```

## Struktura po instalacji

```
~/.local/share/omarchy/     # Główny katalog Omarchy
├── bin/                    # Skrypty utility (~100+ narzędzi)
├── config/                 # Konfiguracje źródłowe
├── default/                # Domyślne ustawienia
└── install/                # Skrypty instalacyjne

~/.config/                  # Twoje konfiguracje (skopiowane z omarchy)
├── hypr/                   # Hyprland
├── waybar/                 # Waybar
├── kitty/                  # Kitty
└── ...                     # Wszystkie inne

~/.local/share/applications/icons/  # Ikony dla webapps
~/.local/state/omarchy/     # Stan (np. marker first-run)
```

## Kluczowe skróty (po instalacji)

- **Super + T** - Terminal (Kitty)
- **Super + Space** - Launcher (Walker/Rofi)
- **Super + Q** - Zamknij okno
- **Super + F** - Fullscreen
- **Super + 1-9** - Przełącz workspace
- **Super + Shift + 1-9** - Przenieś okno na workspace

Więcej w welcome screen po pierwszym logowaniu!

## Pomocne komendy Omarchy

Po instalacji będziesz mieć dostęp do ~100 komend `omarchy-*`:

```bash
omarchy-install-steam        # Instaluj Steam
omarchy-install-docker-dbs   # Instaluj bazy danych Docker
omarchy-cmd-first-run        # Uruchom ponownie first-run
omarchy-version              # Wersja Omarchy
```

Lista wszystkich: `ls ~/.local/share/omarchy/bin/`

## Troubleshooting

### Hyprland nie startuje:

```bash
# Sprawdź logi Hyprland
cat ~/.hyprland.log

# Sprawdź czy SDDM jest włączony
sudo systemctl status sddm
```

### First-run nie uruchomił się:

```bash
# Uruchom ręcznie
omarchy-cmd-first-run
```

### Chcę wrócić do poprzedniej konfiguracji:

```bash
# Skrypt NIE tworzy backupów automatycznie!
# Jeśli masz backup ~/.config/, możesz go przywrócić:
rm -rf ~/.config/
mv ~/.config.backup ~/.config/
```

**WAŻNE**: Zrób backup `~/.config/` przed uruchomieniem skryptu!

## Pytania?

- **Dokumentacja Omarchy**: Sprawdź `docs/` w repo
- **Issues**: https://github.com/basecamp/omarchy/issues
- **Wiki Arch Linux**: https://wiki.archlinux.org/

---

**Uwaga**: Ten skrypt jest **nieoficjalnym** rozszerzeniem Omarchy do instalacji na istniejących systemach. Oficjalny installer (`boot.sh`) jest przeznaczony do instalacji od zera na Btrfs z Limine.
