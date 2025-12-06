#!/bin/bash

# ==========================================
# Neovim Complete Setup für Manjaro/Arch
# ==========================================

set -e  # Bei Fehler abbrechen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper-Funktionen
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

# Installiere Neovim
install_neovim() {
    print_header "Neovim installieren"
    install_if_missing "neovim"
}

# Installiere Clipboard Tools
install_clipboard_tools() {
    print_header "Clipboard Tools installieren"

    # xclip oder xsel für Neovim Clipboard Support
    if command_exists xclip; then
        print_success "xclip bereits installiert"
    elif command_exists xsel; then
        print_success "xsel bereits installiert"
    else
        print_info "Installiere xclip für Clipboard Support..."
        install_if_missing "xclip"
    fi

    # wl-clipboard für Wayland
    if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        install_if_missing "wl-clipboard"
        print_success "wl-clipboard für Wayland installiert"
    fi
}

# Installiere Tree-sitter
install_treesitter() {
    print_header "Tree-sitter installieren"

    # tree-sitter (Library)
    install_if_missing "tree-sitter"

    # tree-sitter-cli
    install_if_missing "tree-sitter-cli"
}

# Installiere LSP Dependencies
install_lsp_dependencies() {
    print_header "LSP Dependencies installieren"

    # Node.js & npm (für viele LSPs)
    install_if_missing "nodejs"
    install_if_missing "npm"

    # Python (sollte schon via pyenv installiert sein)
    print_info "Python via pyenv sollte bereits installiert sein"

    # Ruby (sollte schon installiert sein)
    if command_exists ruby; then
        print_success "Ruby bereits installiert"
    else
        install_if_missing "ruby"
    fi

    # Rust (sollte schon installiert sein)
    if command_exists rustc; then
        print_success "Rust bereits installiert"
    else
        install_if_missing "rust"
    fi

    # Go (sollte schon installiert sein)
    if command_exists go; then
        print_success "Go bereits installiert"
    else
        install_if_missing "go"
    fi

    # Java (sollte schon installiert sein)
    if command_exists java; then
        print_success "Java bereits installiert"
    else
        install_if_missing "jdk-openjdk"
    fi

    # Clang/Clangd für C/C++ - aus Manjaro Repos
    install_if_missing "clang"

    # Git (für Lazy.nvim)
    install_if_missing "git"

    # wget & unzip (für Downloads)
    install_if_missing "wget"
    install_if_missing "unzip"
    install_if_missing "tar"
}

# Installiere LSP Server aus System-Paketen
install_system_lsp_servers() {
    print_header "System LSP Server installieren"

    # Bash Language Server
    if is_installed "bash-language-server"; then
        print_success "bash-language-server bereits installiert"
    else
        print_info "Installiere bash-language-server..."
        sudo pacman -S --noconfirm bash-language-server
        print_success "bash-language-server installiert"
    fi

    # Lua Language Server
    if is_installed "lua-language-server"; then
        print_success "lua-language-server bereits installiert"
    else
        print_info "Installiere lua-language-server..."
        sudo pacman -S --noconfirm lua-language-server
        print_success "lua-language-server installiert"
    fi

    # YAML Language Server
    if is_installed "yaml-language-server"; then
        print_success "yaml-language-server bereits installiert"
    else
        print_info "Installiere yaml-language-server..."
        sudo pacman -S --noconfirm yaml-language-server
        print_success "yaml-language-server installiert"
    fi

    # TypeScript Language Server
    if is_installed "typescript-language-server"; then
        print_success "typescript-language-server bereits installiert"
    else
        print_info "Installiere typescript-language-server..."
        sudo pacman -S --noconfirm typescript-language-server
        print_success "typescript-language-server installiert"
    fi

    # Pyright (Python)
    if is_installed "pyright"; then
        print_success "pyright bereits installiert"
    else
        print_info "Installiere pyright..."
        sudo pacman -S --noconfirm pyright
        print_success "pyright installiert"
    fi

    # Ruff (Python Linter/Formatter)
    if is_installed "ruff"; then
        print_success "ruff bereits installiert"
    else
        print_info "Installiere ruff..."
        sudo pacman -S --noconfirm ruff
        print_success "ruff installiert"
    fi

    # Python Black (Formatter)
    if is_installed "python-black"; then
        print_success "python-black bereits installiert"
    else
        print_info "Installiere python-black..."
        sudo pacman -S --noconfirm python-black
        print_success "python-black installiert"
    fi
}

# Installiere zusätzliche Node.js LSP Server (die nicht in Repos sind)
install_node_lsp_servers() {
    print_header "Zusätzliche Node.js LSP Server installieren"

    if ! command_exists npm; then
        print_warning "npm nicht installiert!"
        return
    fi

    # Neovim Node.js Provider (CHECKHEALTH FIX #2)
    if npm list -g neovim &>/dev/null; then
        print_success "neovim (Node.js Provider) bereits installiert"
    else
        print_info "Installiere neovim Node.js Provider..."
        sudo npm install -g neovim
        print_success "neovim Node.js Provider installiert"
    fi

    # vscode-langservers-extracted (für HTML, CSS, JSON, ESLint)
    local server="vscode-langservers-extracted"
    if npm list -g "$server" &>/dev/null; then
        print_success "$server bereits installiert"
    else
        print_info "Installiere $server..."
        sudo npm install -g "$server"
        print_success "$server installiert"
    fi
}

# Installiere Python LSP Tools (falls nicht via System-Paket)
install_python_lsp_tools() {
    print_header "Zusätzliche Python LSP Tools installieren"

    # Initialisiere pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command_exists pyenv; then
        eval "$(pyenv init -)"
    fi

    if ! command_exists python && ! command_exists python3; then
        print_warning "Python nicht verfügbar!"
        return
    fi

    local py_cmd="python"
    if ! command_exists python; then
        py_cmd="python3"
    fi

    # ruff-lsp (falls nicht via System-Paket installiert)
    local tool="ruff-lsp"
    if command_exists ruff-lsp || $py_cmd -m pip show "$tool" &>/dev/null; then
        print_success "$tool bereits installiert"
    else
        print_info "Installiere $tool..."
        $py_cmd -m pip install --user "$tool"
        print_success "$tool installiert"
    fi
}

# Installiere Ruby Gems
install_ruby_gems() {
    print_header "Ruby Gems installieren"

    if ! command_exists ruby; then
        print_warning "Ruby nicht installiert!"
        return
    fi

    local gems=(
        "neovim"      # Neovim Ruby Provider (CHECKHEALTH FIX #3)
        "ruby-lsp"
        "rubocop"
    )

    for gem in "${gems[@]}"; do
        if gem list -i "^${gem}$" &>/dev/null; then
            print_success "$gem bereits installiert"
        else
            print_info "Installiere $gem..."
            gem install "$gem"
            print_success "$gem installiert"
        fi
    done
}

# Installiere Go Tools
install_go_tools() {
    print_header "Go Tools installieren"

    if ! command_exists go; then
        print_warning "Go nicht installiert!"
        return
    fi

    if command_exists gopls; then
        print_success "gopls bereits installiert"
    else
        print_info "Installiere gopls..."
        go install golang.org/x/tools/gopls@latest
        print_success "gopls installiert"
    fi
}

# Installiere Rust Analyzer
install_rust_analyzer() {
    print_header "Rust Analyzer installieren"

    if ! command_exists rustup; then
        print_warning "Rustup nicht installiert!"
        return
    fi

    print_info "Installiere rust-analyzer..."
    rustup component add rust-analyzer 2>/dev/null || print_success "rust-analyzer bereits installiert"

    print_info "Installiere rust-src..."
    rustup component add rust-src 2>/dev/null || print_success "rust-src bereits installiert"
}

# Installiere JDTLS (Java Language Server)
install_jdtls() {
    print_header "JDTLS installieren"

    if ! command_exists java; then
        print_warning "Java nicht installiert, überspringe JDTLS"
        return
    fi

    local jdtls_path="$HOME/.local/share/nvim/jdtls"

    if [ -d "$jdtls_path" ] && [ -n "$(ls -A $jdtls_path/plugins/*.jar 2>/dev/null)" ]; then
        print_success "JDTLS bereits installiert"
        return
    fi

    print_info "Installiere JDTLS..."
    mkdir -p "$jdtls_path"
    cd "$jdtls_path"

    print_info "Lade JDTLS herunter..."
    wget -q --show-progress https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz

    print_info "Entpacke JDTLS..."
    tar -xzf jdt-language-server-latest.tar.gz
    rm jdt-language-server-latest.tar.gz

    cd - > /dev/null
    print_success "JDTLS installiert in $jdtls_path"
}

# Installiere Lazy.nvim
install_lazy_nvim() {
    print_header "Lazy.nvim installieren"

    local lazy_path="$HOME/.local/share/nvim/lazy/lazy.nvim"

    if [ -d "$lazy_path" ]; then
        print_success "Lazy.nvim bereits installiert"
    else
        print_info "Clone Lazy.nvim..."
        git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$lazy_path"
        print_success "Lazy.nvim installiert"
    fi
}

# Kopiere und passe init.lua an
setup_init_lua() {
    print_header "init.lua einrichten"

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local source_init="$script_dir/init.lua"
    local nvim_config_dir="$HOME/.config/nvim"
    local target_init="$nvim_config_dir/init.lua"

    # Erstelle Config Verzeichnis
    mkdir -p "$nvim_config_dir"

    # Prüfe ob init.lua vorhanden ist
    if [ ! -f "$source_init" ]; then
        print_warning "init.lua nicht im Script-Verzeichnis gefunden!"
        print_info "Überspringe init.lua Setup"
        return 0
    fi

    # Backup erstellen falls vorhanden
    if [ -f "$target_init" ]; then
        local backup_file="$target_init.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Erstelle Backup: $backup_file"
        cp "$target_init" "$backup_file"
        print_success "Backup erstellt"
    fi

    # Erkenne Java Home
    local java_home=""
    if command_exists java; then
        # Versuche Java Home zu finden
        if [ -n "$JAVA_HOME" ]; then
            java_home="$JAVA_HOME"
        elif command_exists archlinux-java; then
            local java_version=$(archlinux-java get 2>/dev/null)
            if [ -n "$java_version" ]; then
                java_home="/usr/lib/jvm/$java_version"
            fi
        fi

        # Fallback: Suche in /usr/lib/jvm
        if [ -z "$java_home" ]; then
            java_home=$(ls -d /usr/lib/jvm/java-*-openjdk 2>/dev/null | head -1)
        fi
    fi

    if [ -z "$java_home" ]; then
        java_home="/usr/lib/jvm/default"
        print_warning "Java Home nicht gefunden, verwende: $java_home"
    else
        print_success "Java Home gefunden: $java_home"
    fi

    # Kopiere und passe Pfade an (überschreibe immer)
    print_info "Kopiere init.lua und passe Pfade an..."

    sed -e "s|local JAVA_HOME = \".*\"|local JAVA_HOME = \"$java_home\"|" \
        -e "s|local JAVA_BIN = JAVA_HOME .. \"/bin/java\"|local JAVA_BIN = \"$(which java 2>/dev/null || echo "$java_home/bin/java")\"|" \
        "$source_init" > "$target_init"

    print_success "init.lua wurde eingerichtet (überschrieben)"
    print_info "Java Home: $java_home"
}

# Erstelle benötigte Verzeichnisse
setup_directories() {
    print_header "Verzeichnisse erstellen"

    mkdir -p "$HOME/.local/share/nvim"
    mkdir -p "$HOME/.local/share/nvim/jdtls"
    mkdir -p "$HOME/.cache/jdtls-workspace"
    mkdir -p "$HOME/.config/nvim"

    print_success "Verzeichnisse erstellt"
}

# Verifiziere Installation
verify_installation() {
    print_header "Installation verifizieren"

    echo ""
    print_info "Neovim:"
    if command_exists nvim; then
        print_success "Neovim: $(nvim --version | head -n1)"
    else
        print_warning "nvim nicht gefunden"
    fi

    echo ""
    print_info "Neovim Provider & Tools:"

    # Clipboard (CHECKHEALTH FIX #1)
    if command_exists xclip || command_exists xsel || command_exists wl-copy; then
        print_success "Clipboard Support ✓"
    else
        print_warning "Clipboard Tool nicht gefunden"
    fi

    # Node.js Provider (CHECKHEALTH FIX #2)
    if npm list -g neovim &>/dev/null 2>&1; then
        print_success "Node.js Provider (neovim) ✓"
    else
        print_warning "Node.js Provider nicht gefunden"
    fi

    # Ruby Provider (CHECKHEALTH FIX #3)
    if gem list -i "^neovim$" &>/dev/null 2>&1; then
        print_success "Ruby Provider (neovim) ✓"
    else
        print_warning "Ruby Provider nicht gefunden"
    fi

    echo ""
    print_info "Tree-sitter:"
    if command_exists tree-sitter; then
        print_success "tree-sitter ✓"
    else
        print_warning "tree-sitter nicht gefunden"
    fi

    if command_exists tree-sitter-cli; then
        print_success "tree-sitter-cli ✓"
    else
        print_warning "tree-sitter-cli nicht gefunden"
    fi

    echo ""
    print_info "LSP Server:"

    # Clangd
    if command_exists clangd; then
        print_success "clangd (C/C++) ✓"
    else
        print_warning "clangd nicht gefunden"
    fi

    # Go
    if command_exists gopls; then
        print_success "gopls (Go) ✓"
    else
        print_warning "gopls nicht gefunden"
    fi

    # Ruby
    if command_exists ruby-lsp; then
        print_success "ruby-lsp (Ruby) ✓"
    else
        print_warning "ruby-lsp nicht gefunden"
    fi

    # Rust
    if command_exists rust-analyzer; then
        print_success "rust-analyzer (Rust) ✓"
    else
        print_warning "rust-analyzer nicht gefunden"
    fi

    # Python
    if command_exists pyright; then
        print_success "pyright (Python) ✓"
    else
        print_warning "pyright nicht gefunden"
    fi

    if command_exists ruff; then
        print_success "ruff (Python) ✓"
    else
        print_warning "ruff nicht gefunden"
    fi

    # TypeScript
    if command_exists typescript-language-server; then
        print_success "typescript-language-server ✓"
    else
        print_warning "typescript-language-server nicht gefunden"
    fi

    # Bash
    if command_exists bash-language-server; then
        print_success "bash-language-server ✓"
    else
        print_warning "bash-language-server nicht gefunden"
    fi

    # YAML
    if command_exists yaml-language-server; then
        print_success "yaml-language-server ✓"
    else
        print_warning "yaml-language-server nicht gefunden"
    fi

    # Java
    local jdtls_path="$HOME/.local/share/nvim/jdtls"
    if [ -d "$jdtls_path" ] && [ -n "$(ls -A $jdtls_path/plugins/*.jar 2>/dev/null)" ]; then
        print_success "jdtls (Java) ✓"
    else
        print_warning "jdtls nicht installiert"
    fi

    # Lua
    if command_exists lua-language-server; then
        print_success "lua-language-server ✓"
    else
        print_warning "lua-language-server nicht gefunden"
    fi

    echo ""
    print_info "Formatters & Linters:"

    command_exists rubocop && print_success "rubocop (Ruby) ✓" || print_warning "rubocop nicht gefunden"
    command_exists black && print_success "black (Python) ✓" || print_warning "black nicht gefunden"

    echo ""
}

# Hauptprogramm
main() {
    print_header "Neovim Complete Setup"

    # Prüfe System
    if [ ! -f "/etc/manjaro-release" ] && [ ! -f "/etc/arch-release" ]; then
        print_error "Dieses Script ist nur für Manjaro/Arch Linux!"
        exit 1
    fi

    print_success "System erkannt: Manjaro/Arch Linux"

    # Installation
    install_neovim
    install_clipboard_tools    # FIX #1: Clipboard Support
    install_treesitter
    install_lsp_dependencies
    setup_directories
    install_lazy_nvim

    # LSP Server installieren (bevorzugt System-Pakete)
    install_system_lsp_servers
    install_node_lsp_servers   # FIX #2: Node.js Provider
    install_python_lsp_tools
    install_ruby_gems          # FIX #3: Ruby Provider
    install_go_tools
    install_rust_analyzer
    install_jdtls

    # init.lua einrichten (mit Backup und Überschreiben)
    setup_init_lua

    # Verifiziere
    verify_installation

    # Finale Nachricht
    print_header "Installation abgeschlossen!"
    echo ""
    print_success "Neovim wurde vollständig eingerichtet"
    echo ""
    print_info "Checkhealth Fixes:"
    echo "  ✓ Clipboard Support (xclip/xsel/wl-clipboard)"
    echo "  ✓ Node.js Provider (npm install -g neovim)"
    echo "  ✓ Ruby Provider (gem install neovim)"
    echo ""
    print_info "Nächste Schritte:"
    echo ""
    echo "  1. Shell neu laden (damit LSP-Tools im PATH sind):"
    echo "     source ~/.bashrc   # oder ~/.zshrc"
    echo ""
    echo "  2. Neovim starten:"
    echo "     nvim"
    echo ""
    echo "  3. Lazy.nvim installiert automatisch alle Plugins beim ersten Start"
    echo "     Warte bis alle Downloads fertig sind"
    echo ""
    echo "  4. Treesitter Parser installieren:"
    echo "     :TSUpdate"
    echo ""
    echo "  5. Health Check durchführen (sollte jetzt grün sein!):"
    echo "     :checkhealth"
    echo ""
    echo "  6. LSP testen mit einer Datei:"
    echo "     - Python:  nvim test.py"
    echo "     - Go:      nvim test.go"
    echo "     - Rust:    nvim test.rs"
    echo "     - Ruby:    nvim test.rb"
    echo "     - Java:    nvim Test.java"
    echo "     - C/C++:   nvim test.c"
    echo ""
    print_info "Wichtige Keybindings:"
    echo "  - <Ctrl+Space>:  Hover Info"
    echo "  - gd:            Gehe zu Definition"
    echo "  - gr:            Zeige Referenzen"
    echo "  - <Leader>a:     Code Actions"
    echo "  - <Leader>r:     Rename"
    echo "  - <Leader>f:     Format"
    echo "  - [d / ]d:       Vorheriger/Nächster Diagnostic"
    echo "  - <Leader>h:     Toggle Inlay Hints"
    echo ""
    print_info "Config Pfad:"
    echo "  ~/.config/nvim/init.lua"
    echo ""
    print_info "LSP Logs (bei Problemen):"
    echo "  :LspLog"
    echo "  ~/.local/state/nvim/lsp.log"
    echo ""
}

# Script ausführen
main "$@"
