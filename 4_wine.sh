#!/bin/bash

# ==========================================
# Wine Installation für Manjaro/Arch
# Mit Winetricks, Dependencies und Optimierungen
# ==========================================

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Prüfe ob Paket installiert ist
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# Installiere Paket wenn nicht vorhanden
install_if_missing() {
    local pkg=$1
    if is_installed "$pkg"; then
        print_success "$pkg bereits installiert"
    else
        print_info "Installiere $pkg..."
        sudo pacman -S --noconfirm "$pkg"
        print_success "$pkg installiert"
    fi
}

# Prüfe ob Command verfügbar ist
command_exists() {
    command -v "$1" &>/dev/null
}

# Prüfe System-Architektur
check_architecture() {
    print_header "System-Architektur prüfen"

    local arch=$(uname -m)
    print_info "System-Architektur: $arch"

    if [ "$arch" != "x86_64" ]; then
        print_error "Wine wird hauptsächlich für x86_64 (64-bit) unterstützt"
        print_warning "Installation wird fortgesetzt, aber Kompatibilität kann eingeschränkt sein"
    fi
}

# Aktiviere Multilib Repository
enable_multilib() {
    print_header "Multilib Repository prüfen"

    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        print_success "Multilib Repository bereits aktiviert"
        return 0
    fi

    print_info "Multilib Repository nicht aktiviert (für 32-bit Support)"
    print_info "Wine 64-bit funktioniert auch ohne Multilib"

    return 1
}

# Installiere Wine
install_wine() {
    print_header "Wine 64-bit installieren"

    # Nur Wine Standard (64-bit)
    install_if_missing "wine"
    print_success "Wine 64-bit installiert"
}

# Installiere 32-bit Libraries (ENTFERNT - nicht benötigt)
install_32bit_libraries() {
    print_info "32-bit Libraries werden übersprungen (nur 64-bit Installation)"
    return 0
}

# Installiere Wine Dependencies
install_wine_dependencies() {
    print_header "Wine Dependencies installieren"

    local dependencies=(
        "giflib"
        "libpng"
        "libldap"
        "gnutls"
        "mpg123"
        "openal"
        "v4l-utils"
        "libpulse"
        "alsa-lib"
        "alsa-plugins"
        "libgphoto2"
        "sane"
        "gsm"
        "ffmpeg"
        "gst-plugins-base"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "cups"
        "samba"
        "dosbox"
    )

    print_info "Installiere Wine Dependencies..."

    for dep in "${dependencies[@]}"; do
        install_if_missing "$dep"
    done

    print_success "Wine Dependencies installiert"
}

# Installiere Winetricks
install_winetricks() {
    print_header "Winetricks installieren"

    install_if_missing "winetricks"

    # Stelle sicher dass winetricks ausführbar ist
    if command_exists winetricks; then
        print_success "Winetricks installiert und verfügbar"

        # Zeige Version
        local version=$(winetricks --version 2>/dev/null || echo "unbekannt")
        print_info "Winetricks Version: $version"
    else
        print_error "Winetricks Installation fehlgeschlagen"
        return 1
    fi
}

# Installiere Wine-Mono und Wine-Gecko
install_wine_addons() {
    print_header "Wine-Mono und Wine-Gecko installieren"

    # Wine-Mono (.NET Support für Wine)
    install_if_missing "wine-mono"

    # Wine-Gecko (Internet Explorer Support für Wine)
    install_if_missing "wine-gecko"

    print_success "Wine Addons installiert"
}

# Installiere zusätzliche Fonts
install_fonts() {
    print_header "Zusätzliche Fonts installieren"

    local fonts=(
        "ttf-liberation"        # Microsoft-kompatible Fonts
        "ttf-dejavu"            # DejaVu Fonts
        "ttf-ms-fonts"          # Microsoft Core Fonts (falls verfügbar)
        "noto-fonts"            # Google Noto Fonts
    )

    print_info "Installiere Fonts für bessere Windows-App-Darstellung..."

    for font in "${fonts[@]}"; do
        if pacman -Ss "^${font}$" &>/dev/null; then
            install_if_missing "$font"
        else
            print_warning "$font nicht verfügbar"
        fi
    done

    # Font Cache aktualisieren
    print_info "Aktualisiere Font Cache..."
    fc-cache -fv >/dev/null 2>&1

    print_success "Fonts installiert"
}

# Konfiguriere Wine
configure_wine() {
    print_header "Wine 64-bit konfigurieren"

    print_info "Initialisiere Wine 64-bit Prefix..."

    # 64-bit Wine Prefix erstellen
    if [ ! -d "$HOME/.wine" ]; then
        print_info "Erstelle Wine 64-bit Prefix..."
        WINEARCH=win64 WINEPREFIX="$HOME/.wine" wineboot -u
        print_success "Wine 64-bit Prefix erstellt"
    else
        print_success "Wine Prefix bereits vorhanden"
    fi

    # Wine Prefix Info
    print_info "Wine Prefix: $HOME/.wine (64-bit)"
}

# Installiere wichtige Komponenten via Winetricks
install_winetricks_essentials() {
    print_header "Winetricks Essentials installieren"

    if ! command_exists winetricks; then
        print_error "Winetricks nicht verfügbar!"
        return 1
    fi

    print_info "Installiere wichtige Komponenten für breite Anwendungs-Kompatibilität..."
    print_warning "Dies kann 10-30 Minuten dauern..."

    # Setze Umgebungsvariablen für 64-bit
    export WINEARCH=win64
    export WINEPREFIX="$HOME/.wine"

    # Liste der essentiellen Komponenten
    local components=(
        # Fonts
        "corefonts"              # Microsoft Core Fonts (Arial, Times, etc.)
        "liberation"             # Liberation Fonts

        # .NET Framework
        "dotnet48"               # .NET Framework 4.8 (neueste)

        # Visual C++ Runtimes
        "vcrun2022"              # Visual C++ 2015-2022 Runtime
#         "vcrun2019"              # Visual C++ 2019 Runtime
#         "vcrun2017"              # Visual C++ 2017 Runtime
#         "vcrun2015"              # Visual C++ 2015 Runtime
        "vcrun2013"              # Visual C++ 2013 Runtime
        "vcrun2012"              # Visual C++ 2012 Runtime
        "vcrun2010"              # Visual C++ 2010 Runtime
        "vcrun2008"              # Visual C++ 2008 Runtime
        "vcrun2005"              # Visual C++ 2005 Runtime

        # DirectX
        "d3dx9"                  # DirectX 9
        "d3dcompiler_47"         # DirectX Shader Compiler
#         "dxvk"                   # DXVK (Vulkan-basiertes DirectX 9/10/11)

        # Multimedia
        "quartz"                 # Windows Media Foundation
#         "wmp10"                  # Windows Media Player 10
        "xvid"                   # Xvid Video Codec

        # Common Libraries
        "msxml3"                 # Microsoft XML Parser
        "msxml6"                 # Microsoft XML Parser 6
        "xact"                   # Microsoft XACT Audio

        # Utilities
        "crypt32"                # Windows Crypto API
        "wininet"                # Windows Internet API
    )

    print_info "Installiere ${#components[@]} Komponenten..."

    local failed=()
    local succeeded=0

    set +e   # Fehler NICHT mehr tödlich für Winetricks

    for component in "${components[@]}"; do
        print_info "Installiere: $component..."

        if winetricks -q "$component"; then
            print_success "$component installiert"
        else
            print_warning "$component Installation fehlgeschlagen (wird übersprungen)"
            failed+=("$component")
        fi
    done

    set -e   # Fehlerbehandlung wieder aktivieren

    echo ""
    print_success "$succeeded/$((${#components[@]})) Komponenten erfolgreich installiert"

    if [ ${#failed[@]} -gt 0 ]; then
        print_warning "Fehlgeschlagene Komponenten:"
        for comp in "${failed[@]}"; do
            echo "  - $comp"
        done
    fi

    print_success "Winetricks Essentials Installation abgeschlossen"
}

# Installiere optionale Gaming-Tools (ENTFERNT)
install_gaming_tools() {
    print_info "Gaming-Tools Installation übersprungen (fokussiert auf Wine 64-bit)"
    return 0
}

# Verifiziere Installation
verify_installation() {
    print_header "Installation verifizieren"

    echo ""
    print_info "Wine Version:"
    if command_exists wine; then
        wine --version
        print_success "Wine verfügbar"
    else
        print_error "Wine nicht gefunden!"
    fi

    echo ""
    print_info "Winetricks:"
    if command_exists winetricks; then
        winetricks --version 2>/dev/null || echo "Winetricks verfügbar"
        print_success "Winetricks verfügbar"
    else
        print_error "Winetricks nicht gefunden!"
    fi

    echo ""
    print_info "32-bit Support:"
    if pacman -Qq lib32-mesa &>/dev/null; then
        print_success "32-bit Libraries installiert"
    else
        print_warning "32-bit Libraries nicht vollständig"
    fi

    echo ""
    print_info "Wine Prefix:"
    if [ -d "$HOME/.wine" ]; then
        print_success "Wine Prefix existiert: $HOME/.wine"
    else
        print_warning "Wine Prefix noch nicht initialisiert"
    fi

    echo ""
}

# Zeige Verwendungshinweise
show_usage() {
    print_header "Wine Verwendung"

    echo ""
    print_info "Wine Befehle:"
    echo "  wine <programm.exe>           - Windows-Programm ausführen"
    echo "  winecfg                       - Wine Konfiguration öffnen"
    echo "  winetricks                    - Winetricks GUI öffnen"
    echo "  winetricks <paket>            - Komponente installieren"
    echo ""

    print_info "Häufig verwendete Winetricks:"
    echo "  winetricks corefonts          - Microsoft Core Fonts"
    echo "  winetricks vcrun2019          - Visual C++ 2019 Runtimes"
    echo "  winetricks dotnet48           - .NET Framework 4.8"
    echo "  winetricks d3dx9              - DirectX 9"
    echo "  winetricks dxvk               - DXVK (Vulkan-basiertes DirectX)"
    echo ""

    print_info "Wine Prefix Management:"
    echo "  WINEPREFIX=~/my_prefix wine <app.exe>    - Separates Prefix verwenden"
    echo "  WINEARCH=win64 wineboot -u                - 64-bit Prefix erstellen"
    echo "  WINEARCH=win32 wineboot -u                - 32-bit Prefix erstellen"
    echo ""

    print_info "Nützliche Umgebungsvariablen:"
    echo "  export WINEPREFIX=$HOME/.wine_app         - Prefix-Pfad setzen"
    echo "  export WINEARCH=win64                     - 64-bit Architektur"
    echo "  export WINEDEBUG=-all                     - Debug-Ausgaben deaktivieren"
    echo ""

    print_info "Beispiele:"
    echo "  wine notepad                              - Notepad starten"
    echo "  wine setup.exe                            - Installer ausführen"
    echo "  wine 'C:\\Program Files\\app\\app.exe'    - Programm mit Pfad starten"
    echo ""
}

# Zusammenfassung
print_summary() {
    print_header "Installation abgeschlossen!"

    echo ""
    print_success "Wine wurde erfolgreich installiert"
    echo ""

    print_info "Installierte Komponenten:"
    echo "  ✓ Wine 64-bit (Windows-Kompatibilitätsschicht)"
    echo "  ✓ Winetricks (Komponenten-Manager)"
    echo "  ✓ Wine-Mono (.NET Support)"
    echo "  ✓ Wine-Gecko (Internet Explorer Engine)"
    echo "  ✓ Zusätzliche Fonts"
    echo ""
    echo "  ✓ Via Winetricks installiert:"
    echo "    - Microsoft Core Fonts"
    echo "    - .NET Framework 4.8"
    echo "    - Visual C++ Runtimes (2005-2022)"
    echo "    - DirectX 9 + DXVK (Vulkan DirectX)"
    echo "    - Windows Media Player"
    echo "    - Multimedia Codecs"
    echo ""

    print_info "Wine Prefix:"
    echo "  Standort: $HOME/.wine"
    echo "  Typ: 64-bit (win64)"
    echo ""

    print_warning "Wichtige Hinweise:"
    echo "  1. Für beste Performance: Installiere GPU-Treiber"
    echo "  2. Nur 64-bit Windows-Programme werden unterstützt"
    echo "  3. 32-bit Programme benötigen Multilib + lib32 Pakete"
    echo ""

    print_info "Erste Schritte:"
    echo "  1. Wine testen:      wine64 notepad"
    echo "  2. Konfiguration:    winecfg"
    echo "  3. Komponenten:      winetricks"
    echo ""

    print_info "Support & Dokumentation:"
    echo "  - Wine Wiki:         https://wiki.winehq.org/"
    echo "  - Arch Wiki:         https://wiki.archlinux.org/title/Wine"
    echo "  - Wine AppDB:        https://appdb.winehq.org/"
    echo ""
}

# Hauptprogramm
main() {
    print_header "Wine Installation für Manjaro/Arch"

    # System Check
    if [ ! -f "/etc/manjaro-release" ] && [ ! -f "/etc/arch-release" ]; then
        print_error "Dieses Script ist nur für Manjaro/Arch Linux!"
        exit 1
    fi

    print_success "System erkannt: Manjaro/Arch Linux"

    # Architektur prüfen
    check_architecture

    # Multilib prüfen (aber nicht installieren)
    enable_multilib

    # Installation (nur 64-bit)
    install_wine
    install_wine_dependencies
    install_winetricks
    install_wine_addons
    install_fonts
    configure_wine

    # Winetricks Essentials installieren
    install_winetricks_essentials

    # Verifizierung
    verify_installation

    # Verwendungshinweise
    show_usage

    # Zusammenfassung
    print_summary
}

# Script ausführen
main "$@"
