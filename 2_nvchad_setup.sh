#!/bin/bash

# NvChad Installation Script für Manjaro
# Dieses Script installiert Neovim und entpackt eine vorkonfigurierte NvChad-Installation

set -e  # Bei Fehler abbrechen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}NvChad Installation Script${NC}"
echo -e "${BLUE}================================${NC}\n"

# Prüfe ob Script als root ausgeführt wird
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Bitte führe dieses Script NICHT als root aus!${NC}"
    exit 1
fi

# Prüfe ob nvim.zip existiert
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_ZIP="$SCRIPT_DIR/nvim.zip"

if [ ! -f "$NVIM_ZIP" ]; then
    echo -e "${RED}Fehler: nvim.zip wurde nicht gefunden!${NC}"
    echo -e "${RED}Stelle sicher, dass nvim.zip im gleichen Verzeichnis wie dieses Script liegt.${NC}"
    echo -e "${RED}Aktuelles Verzeichnis: $SCRIPT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ nvim.zip gefunden${NC}\n"

# Schritt 1: Neovim installieren
echo -e "${BLUE}[1/4] Installiere Neovim...${NC}"

if command -v nvim &> /dev/null; then
    echo -e "${YELLOW}Neovim ist bereits installiert.${NC}"
    nvim --version | head -n 1
else
    echo "Installiere Neovim über pacman..."
    sudo pacman -S --noconfirm neovim
    echo -e "${GREEN}✓ Neovim erfolgreich installiert${NC}"
fi

# Schritt 2: Abhängigkeiten installieren
echo -e "\n${BLUE}[2/4] Installiere zusätzliche Abhängigkeiten...${NC}"

DEPENDENCIES=(
    "git"           # Für Lazy.nvim
    "base-devel"    # Build tools
    "unzip"         # Zum Entpacken
    "ripgrep"       # Für Telescope
    "fd"            # Für Telescope file finder
    "nodejs"        # Für LSPs
    "npm"           # Für LSPs
    "python-pip"    # Für Python LSP
    "lazygit"       # Für Git integration in NVIM
)

for dep in "${DEPENDENCIES[@]}"; do
    if pacman -Qi "$dep" &> /dev/null; then
        echo -e "${GREEN}✓ $dep bereits installiert${NC}"
    else
        echo "Installiere $dep..."
        sudo pacman -S --noconfirm "$dep"
    fi
done

# Schritt 2.1: npm Pakete installieren (typescript, jsregexp, usw.)
echo -e "\n${BLUE}[2.1/4] Installiere npm-Pakete...${NC}"

npm install -g typescript

echo -e "${GREEN}✓ npm-Pakete erfolgreich installiert${NC}"

# Schritt 3: Alte Config sichern und neue entpacken
echo -e "\n${BLUE}[3/4] Entpacke NvChad Konfiguration...${NC}"

CONFIG_DIR="$HOME/.config/nvim"

# Backup erstellen falls bereits eine Config existiert
if [ -d "$CONFIG_DIR" ]; then
    BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Bestehende Neovim-Konfiguration gefunden.${NC}"
    echo -e "${YELLOW}Erstelle Backup in: $BACKUP_DIR${NC}"
    mv "$CONFIG_DIR" "$BACKUP_DIR"
fi

# Erstelle .config Verzeichnis falls es nicht existiert
mkdir -p "$HOME/.config"

# Entpacke nvim.zip
echo "Entpacke nvim.zip nach $HOME/.config/..."
unzip -q "$NVIM_ZIP" -d "$HOME/.config/"

if [ -d "$CONFIG_DIR" ]; then
    echo -e "${GREEN}✓ NvChad Konfiguration erfolgreich entpackt${NC}"
else
    echo -e "${RED}Fehler: Konfiguration wurde nicht korrekt entpackt!${NC}"
    exit 1
fi

# Schritt 4: Permissions setzen
echo -e "\n${BLUE}[4/4] Setze Berechtigungen...${NC}"
chmod -R u+rw "$CONFIG_DIR"
echo -e "${GREEN}✓ Berechtigungen gesetzt${NC}"

# Abschluss
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}Installation erfolgreich!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Nächste Schritte:${NC}"
echo -e "1. Starte Neovim mit: ${BLUE}nvim${NC}"
echo -e "2. Führe in Neovim aus: ${BLUE}:MasonInstallAll${NC}"
echo -e "3. Warte bis alle LSP-Server installiert sind"
echo -e "4. Starte Neovim neu\n"

echo -e "${YELLOW}Benötigte LSP-Server werden automatisch installiert:${NC}"
echo -e "  • jdtls (Java)"
echo -e "  • pyright (Python)"
echo -e "  • gopls (Go)"
echo -e "  • rust-analyzer (Rust)"
echo -e "  • clangd (C/C++)"
echo -e "  • typescript-language-server (JS/TS)"
echo -e "  • html, cssls (HTML/CSS)\n"

echo -e "${GREEN}Viel Spaß mit NvChad! 🚀${NC}\n"

# Optional: Neovim direkt starten
read -p "Möchtest du Neovim jetzt starten? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[JjYy]$ ]]; then
    nvim
fi
