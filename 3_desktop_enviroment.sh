#!/bin/bash

# ==========================================
# Manjaro Apps Installer
# Installiert wichtige Anwendungen mit optionalen Dependencies
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

# System Update
update_system() {
    print_header "System aktualisieren"
    print_info "Aktualisiere Paketdatenbank..."
    sudo pacman -Sy
    print_success "System aktualisiert"
}

# Evolution (E-Mail Client)
install_evolution() {
    print_header "Evolution installieren"

    install_if_missing "evolution"

    # Optionale Dependencies
    local optional_deps=(
        "evolution-ews"           # Exchange Web Services
        "evolution-bogofilter"    # Spam-Filter
        "evolution-spamassassin"  # Spam-Filter
        "highlight"               # Syntax Highlighting
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done
}

# Telegram
install_telegram() {
    print_header "Telegram installieren"
    install_if_missing "telegram-desktop"
}

# GIMP (Bildbearbeitung)
install_gimp() {
    print_header "GIMP installieren"

    install_if_missing "gimp"

    # Optionale Dependencies
    local optional_deps=(
        "gutenprint"              # Drucker-Support
        "poppler-glib"            # PDF-Import
        "alsa-lib"                # Audio
        "ghostscript"             # PostScript-Support
        "gvfs"                    # Netzwerk-Dateizugriff
        "libwebp"                 # WebP-Format
        "libheif"                 # HEIF-Format
        "libavif"                 # AVIF-Format
    )

    for dep in "${optional_deps[@]}"; do
        install_if_missing "$dep"
    done
}

# Krita (Digitale Malerei)
install_krita() {
    print_header "Krita installieren"

    install_if_missing "krita"

    # Optionale Dependencies
    local optional_deps=(
        "krita-plugin-gmic"       # G'MIC Plugin
        "poppler-qt6"             # PDF-Import
        "ffmpeg"                  # Video-Export
        "python-pyqt6"            # Python Scripting
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done
}

# Blender (3D)
install_blender() {
    print_header "Blender installieren"

    install_if_missing "blender"

    # Optionale Dependencies
    local optional_deps=(
        "libdecor"                # Wayland decoration
        "libspnav"                # 3D Mouse Support
        "openimageio"             # Erweiterte Bildformate
        "openxr"                  # VR Support
        "openvdb"                 # Volumetric Data
        "openshadinglanguage"     # Shading Language
        "embree"                  # Ray Tracing
        "opencolorio"             # Color Management
        "alembic"                 # 3D Format
        "openpgl"                 # Path Guiding
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done
}

# Inkscape (Vektor-Grafik)
install_inkscape() {
    print_header "Inkscape installieren"

    install_if_missing "inkscape"

    # Optionale Dependencies
    local optional_deps=(
        "fig2dev"                 # XFig-Import
        "gvfs"                    # Netzwerk-Dateizugriff
        "imagemagick"             # Bitmap-Import
        "libcdr"                  # CorelDRAW-Import
        "libvisio"                # Visio-Import
        "libwpg"                  # WordPerfect-Grafik
        "poppler-glib"            # PDF-Import
        "python-numpy"            # Scripting
        "python-lxml"             # SVG-Verarbeitung
        "scour"                   # SVG-Optimierung
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done
}

# Ardour (DAW)
install_ardour() {
    print_header "Ardour installieren"

    install_if_missing "ardour"

    # Prüfe Audio-System: PipeWire oder JACK2
    local audio_system=""

    if is_installed "pipewire-pulse"; then
        # PipeWire ist installiert - verwende pipewire-jack
        audio_system="pipewire"

        # pipewire-jack installieren (ersetzt jack2)
        if is_installed "jack2"; then
            print_warning "JACK2 ist installiert, aber PipeWire ist aktiv"
            print_info "PipeWire-JACK ersetzt JACK2 (moderner, besser)"
            print_info "Entferne JACK2 und installiere pipewire-jack? (J/n)"
            read -r response

            if [[ "$response" =~ ^([jJ][aA]|[jJ]|)$ ]]; then
                sudo pacman -Rdd --noconfirm jack2 2>/dev/null || true
                install_if_missing "pipewire-jack"
                print_success "PipeWire-JACK installiert (JACK2 entfernt)"
            else
                print_warning "Behalte JACK2 (pipewire-jack nicht installiert)"
            fi
        else
            install_if_missing "pipewire-jack"
        fi

    elif is_installed "pulseaudio"; then
        # PulseAudio ist installiert
        audio_system="pulseaudio"
        install_if_missing "jack2"
        install_if_missing "pulseaudio-jack"

    else
        # Kein Audio-System erkannt - Default zu PipeWire
        audio_system="pipewire"
        install_if_missing "pipewire-pulse"
        install_if_missing "pipewire-jack"
    fi

    # Andere optionale Dependencies
    local optional_deps=(
        "harvid"                  # Video Timeline
        "xjadeo"                  # Video Monitor
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done

    if [[ "$audio_system" == "pipewire" ]]; then
        print_success "Audio-System: PipeWire-JACK (empfohlen für Pro-Audio)"
        print_info "JACK-Apps starten mit: pw-jack <app>"
    else
        print_success "Audio-System: JACK2 mit PulseAudio"
    fi
}

# Audacity
install_audacity() {
    print_header "Audacity installieren"

    install_if_missing "audacity"

    # Optionale Dependencies
    local optional_deps=(
        "ffmpeg"                  # Erweiterte Audio-Formate
        "lame"                    # MP3-Export
    )

    for dep in "${optional_deps[@]}"; do
        install_if_missing "$dep"
    done
}

# Tenacity (Audacity Fork)
install_tenacity() {
    print_header "Tenacity installieren"

    if pacman -Ss "^tenacity$" &>/dev/null; then
        install_if_missing "tenacity"

        # Optionale Dependencies (ähnlich wie Audacity)
        local optional_deps=(
            "ffmpeg"
            "lame"
        )

        for dep in "${optional_deps[@]}"; do
            install_if_missing "$dep"
        done
    else
        print_warning "Tenacity nicht in Repos gefunden (evtl. AUR benötigt)"
        print_info "Installation via AUR: yay -S tenacity"
    fi
}

# Kdenlive (Video-Editor)
install_kdenlive() {
    print_header "Kdenlive installieren"

    install_if_missing "kdenlive"

    # Optionale Dependencies
    local optional_deps=(
        "dvgrab"                  # DV-Aufnahme
        "recordmydesktop"         # Screen Recording
        "xine-ui"                 # Video-Vorschau
        "opencv"                  # Motion Tracking
        "dvdauthor"               # DVD-Authoring
        "genisoimage"             # ISO-Erstellung
        "frei0r-plugins"          # Effekte
        "mediainfo"               # Media-Analyse
        "noise-suppression-for-voice"  # Rauschunterdrückung
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done
}

# VS Code
install_vscode() {
    print_header "VS Code installieren"
    install_if_missing "code"
}

# Zed Editor
install_zed() {
    print_header "Zed Editor installieren"
    install_if_missing "zed"
}

# IntelliJ IDEA Community
install_intellij() {
    print_header "IntelliJ IDEA Community installieren"
    install_if_missing "intellij-idea-community-edition"
}

# Godot Engine
install_godot() {
    print_header "Godot Engine installieren"

    install_if_missing "godot"

    # Optionale Dependencies
    local optional_deps=(
        "godot-export-templates"  # Export Templates
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done
}

# Pencil2D
install_pencil2d() {
    print_header "Pencil2D installieren"
    install_if_missing "pencil2d"
}

# OpenToonz
install_opentoonz() {
    print_header "OpenToonz installieren"
    install_if_missing "opentoonz"
}

# Synfig Studio
install_synfig() {
    print_header "Synfig Studio installieren"
    install_if_missing "synfigstudio"
}

# VLC mit allen Plugins
install_vlc() {
    print_header "VLC mit Plugins installieren"

    install_if_missing "vlc"

    # Alle verfügbaren Plugins
    local plugins=(
        "phonon-qt6-vlc"          # Qt6 Backend
        "libdvdcss"               # DVD-Entschlüsselung
        "libdvdread"              # DVD-Lesen
        "libdvdnav"               # DVD-Navigation
        "libbluray"               # Blu-ray Support
        "libva-intel-driver"      # Intel Hardware-Beschleunigung
        "libva-mesa-driver"       # Mesa Hardware-Beschleunigung
        "libva-vdpau-driver"      # VDPAU Support
        "ffmpeg"                  # Codec-Unterstützung
        "gstreamer"               # Streaming
        "libmad"                  # MP3-Decoder
        "libmpeg2"                # MPEG2-Decoder
        "libtheora"               # Theora-Codec
        "libvorbis"               # Vorbis-Codec
        "flac"                    # FLAC-Codec
        "opus"                    # Opus-Codec
        "x264"                    # H.264-Encoder
        "x265"                    # H.265-Encoder
        "libvpx"                  # VP8/VP9-Codec
        "aom"                     # AV1-Codec
    )

    for plugin in "${plugins[@]}"; do
        if pacman -Ss "^${plugin}$" &>/dev/null; then
            install_if_missing "$plugin"
        fi
    done
}

# Tor Browser
install_tor_browser() {
    print_header "Tor Browser installieren"
    install_if_missing "torbrowser-launcher"
    print_info "Starte nach Installation: torbrowser-launcher"
}

# OBS Studio
install_obs() {
    print_header "OBS Studio installieren"

    install_if_missing "obs-studio"

    # Optionale Dependencies & Plugins
    local optional_deps=(
        "ffmpeg"                  # Recording/Streaming
        "libfdk-aac"              # AAC-Encoder
        "intel-media-driver"      # Intel QSV
        "libva-intel-driver"      # Intel VAAPI
        "libva-mesa-driver"       # AMD/Intel VAAPI
        "v4l2loopback-dkms"       # Virtual Camera
        "swig"                    # Scripting
        "luajit"                  # Lua Scripting
        "python"                  # Python Scripting
        "vlc"                     # VLC Source
    )

    for dep in "${optional_deps[@]}"; do
        if pacman -Ss "^${dep}$" &>/dev/null; then
            install_if_missing "$dep"
        fi
    done
}

# Helix Editor
install_helix() {
    print_header "Helix Editor installieren"

    install_if_missing "helix"

    print_info "Language Server installiert (bereits via dev-setup):"
    print_info "  - bash-language-server, gopls, rust-analyzer, etc."
}

# F3D Viewer
install_f3d() {
    print_header "F3D Viewer installieren"

    if pacman -Ss "^f3d$" &>/dev/null; then
        install_if_missing "f3d"

        # Optionale Dependencies
        local optional_deps=(
            "opencascade"         # CAD-Format-Support
            "ospray"              # Ray Tracing
        )

        for dep in "${optional_deps[@]}"; do
            if pacman -Ss "^${dep}$" &>/dev/null; then
                install_if_missing "$dep"
            fi
        done
    else
        print_warning "F3D nicht in Repos gefunden"
        print_info "Installation via AUR: yay -S f3d"
    fi
}

# Zusammenfassung
print_summary() {
    print_header "Installation abgeschlossen!"

    echo ""
    print_info "Installierte Anwendungen:"
    echo ""
    echo "  📧 E-Mail & Kommunikation:"
    echo "    - Evolution"
    echo "    - Telegram Desktop"
    echo ""
    echo "  🎨 Grafik & Design:"
    echo "    - GIMP"
    echo "    - Krita"
    echo "    - Inkscape"
    echo "    - Blender"
    echo ""
    echo "  🎬 Video & Animation:"
    echo "    - Kdenlive"
    echo "    - OBS Studio"
    echo "    - Pencil2D"
    echo "    - OpenToonz"
    echo "    - Synfig Studio"
    echo ""
    echo "  🎵 Audio:"
    echo "    - Ardour"
    echo "    - Audacity"
    echo "    - Tenacity"
    echo ""
    echo "  💻 Entwicklung:"
    echo "    - VS Code"
    echo "    - Zed"
    echo "    - IntelliJ IDEA Community"
    echo "    - Helix"
    echo ""
    echo "  🎮 Game Development:"
    echo "    - Godot Engine"
    echo ""
    echo "  📺 Media:"
    echo "    - VLC (mit allen Plugins)"
    echo "    - F3D Viewer"
    echo ""
    echo "  🔒 Sicherheit:"
    echo "    - Tor Browser"
    echo ""
    print_info "Hinweise:"
    echo "  - Einige Pakete sind nur via AUR verfügbar"
    echo "  - AUR Helper: yay -S <paket>"
    echo "  - Hardware-Beschleunigung für Video: ggf. GPU-Treiber prüfen"
    echo ""
}

# Hauptprogramm
main() {
    print_header "Manjaro Apps Installer"

    # System Check
    if [ ! -f "/etc/manjaro-release" ] && [ ! -f "/etc/arch-release" ]; then
        print_error "Dieses Script ist nur für Manjaro/Arch Linux!"
        exit 1
    fi

    print_success "System erkannt: Manjaro/Arch Linux"

    # System Update
    update_system

    # Installationen
    install_evolution
    install_telegram
    install_gimp
    install_krita
    install_blender
    install_inkscape
    install_ardour
    install_audacity
    install_tenacity
    install_kdenlive
    install_vscode
    install_zed
    install_intellij
    install_godot
    install_pencil2d
    install_opentoonz
    install_synfig
    install_vlc
    install_tor_browser
    install_obs
    install_helix
    install_f3d

    # AUR Helper & Pakete (optional, falls benötigt)
    # install_aur_helper
    # install_aur_packages

    # Zusammenfassung
    print_summary
}

# Script ausführen
main "$@"
