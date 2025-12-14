#!/bin/bash

# ==========================================
# Dev Environment Setup für Manjaro/Arch
# Programmiersprachen, Shells & CLI Tools
# Bevorzugt pacman Pakete über externe Quellen
# ==========================================

set -e  # Bei Fehler abbrechen

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'
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

# Installiere pyenv (bevorzugt aus Repo)
install_pyenv() {
    print_header "pyenv installieren"

    # Prüfe ob pyenv als Paket verfügbar ist
    if pacman -Ss '^pyenv$' &>/dev/null; then
        install_if_missing "pyenv"
        print_success "pyenv aus Manjaro Repo installiert"
        # KEIN return!
    elif command_exists pyenv; then
        print_success "pyenv bereits installiert"
        # KEIN return!
    else
        print_warning "pyenv nicht in Repos gefunden, installiere aus GitHub..."
        curl https://pyenv.run | bash
    fi

    # Temporär pyenv für diese Session laden (IMMER!)
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true

    # pyenv-virtualenv Plugin via Git installieren (WIRD JETZT IMMER GEPRÜFT!)
    local plugin_dir="$HOME/.pyenv/plugins/pyenv-virtualenv"
    if [ ! -d "$plugin_dir" ]; then
        print_info "pyenv-virtualenv Plugin nicht gefunden — installiere via Git..."
        mkdir -p "$HOME/.pyenv/plugins"
        git clone https://github.com/pyenv/pyenv-virtualenv.git "$plugin_dir"
        if [ $? -eq 0 ]; then
            print_success "pyenv-virtualenv Plugin erfolgreich installiert"
        else
            print_error "Fehler beim Klonen von pyenv-virtualenv"
            return 1
        fi
    else
        print_success "pyenv-virtualenv Plugin bereits vorhanden"
    fi

    print_success "pyenv installiert"
}

# Setup Python mit pyenv (Version 3.12.x)
setup_python_with_pyenv() {
    print_header "Python 3.12.x mit pyenv einrichten"

    # Initialisiere pyenv für diese Session
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true

    # Finde neueste Python 3.12.x Version
    print_info "Suche neueste Python 3.12.x Version..."
    local python_312=$(pyenv install --list | grep -E '^\s*3\.12\.[0-9]+$' | tail -1 | tr -d ' ')

    if [ -z "$python_312" ]; then
        print_error "Keine Python 3.12.x Version gefunden!"
        print_info "Verfügbare Versionen anzeigen mit: pyenv install --list | grep 3.12"
        return 1
    fi

    print_info "Neueste Python 3.12.x Version: $python_312"

    # Prüfe ob bereits installiert
    if pyenv versions 2>/dev/null | grep -q "$python_312"; then
        print_success "Python $python_312 bereits installiert"
    else
        print_info "Installiere Python $python_312 mit pyenv..."
        print_warning "Dies kann einige Minuten dauern..."
        pyenv install "$python_312"
        print_success "Python $python_312 installiert"
    fi

    # Setze als global version
    print_info "Setze Python $python_312 als global..."
    pyenv global "$python_312"

    # Aktualisiere pip
    print_info "Aktualisiere pip..."
    pip install --upgrade pip

    print_success "Python $python_312 ist aktiv ($(python --version))"
}

# Installiere pipx
install_pipx() {
    print_header "pipx installieren"

    # Stelle sicher dass pyenv initialisiert ist
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true

    if command_exists pipx; then
        print_success "pipx bereits installiert"
        return
    fi

    if ! command_exists python && ! command_exists python3; then
        print_error "Python nicht verfügbar, kann pipx nicht installieren"
        return 1
    fi

    local py_cmd="python"
    if ! command_exists python && command_exists python3; then
        py_cmd="python3"
    fi

    print_info "Installiere pipx..."
    $py_cmd -m pip install --user pipx

    # Stelle sicher dass ~/.local/bin im PATH ist
    export PATH="$HOME/.local/bin:$PATH"

    # pipx ensurepath ausführen
    if command_exists pipx; then
        $py_cmd -m pipx ensurepath
        print_success "pipx installiert und konfiguriert"
    else
        print_warning "pipx Installation möglicherweise fehlgeschlagen"
        return 1
    fi
}

# Installiere Tool via pipx
install_via_pipx() {
    local tool=$1
    local check_cmd=${2:-$tool}  # Falls Command anders heißt als Paket

    if command_exists "$check_cmd" || pipx list 2>/dev/null | grep -q "package $tool"; then
        print_success "$tool bereits installiert"
    else
        print_info "Installiere $tool via pipx..."
        if pipx install "$tool"; then
            print_success "$tool installiert (pipx)"
        else
            print_warning "$tool Installation fehlgeschlagen"
            return 1
        fi
    fi
}

# Installiere Python LSP Tools via pipx
install_python_lsp_tools() {
    print_header "Python LSP Tools installieren (via pipx)"

    if ! command_exists pipx; then
        print_warning "pipx nicht verfügbar, überspringe LSP Tools"
        return
    fi

    # LSP Server und Tools
    local lsp_tools=(
        "ruff-lsp"           # Ruff LSP Server (Fast Python Linter)
        "python-lsp-server"  # Python Language Server
    )

    for tool in "${lsp_tools[@]}"; do
        install_via_pipx "$tool"
    done

    print_success "LSP Tools installiert - verfügbar in allen pyenv Versionen"
}

# Setup Java mit archlinux-java
setup_java() {
    print_header "Java mit archlinux-java einrichten"

    # Installiere OpenJDK
    install_if_missing "jdk-openjdk"

    if ! command_exists archlinux-java; then
        print_warning "archlinux-java nicht verfügbar"
        return
    fi

    print_info "Verfügbare Java Versionen:"
    archlinux-java status

    # Prüfe ob default Java gesetzt ist
    local current_java=$(archlinux-java get 2>/dev/null)

    if [ -n "$current_java" ]; then
        print_success "Java Standard bereits gesetzt: $current_java"
    else
        # Setze default Java
        local java_default=$(archlinux-java status | grep -oP 'java-\d+-openjdk' | head -1)
        if [ -n "$java_default" ]; then
            print_info "Setze $java_default als Standard..."
            sudo archlinux-java set "$java_default"
            print_success "$java_default als Standard gesetzt"
        else
            print_warning "Keine Java Version gefunden"
        fi
    fi

    # Zeige aktive Version
    if command_exists java; then
        print_info "Java Version: $(java -version 2>&1 | head -n 1)"
    fi
}

# Installiere Oh My Posh (bevorzugt aus AUR/Repo)
install_oh_my_posh() {
    print_header "Oh My Posh installieren"

    # Prüfe ob oh-my-posh Paket verfügbar ist
    if pacman -Ss '^oh-my-posh$' &>/dev/null; then
        install_if_missing "oh-my-posh"
        print_success "oh-my-posh aus Repo installiert"
    elif command_exists oh-my-posh; then
        print_success "oh-my-posh bereits installiert"
    else
        print_warning "oh-my-posh nicht in Repos, installiere manuell..."
        mkdir -p "$HOME/.local/bin"
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
        print_success "oh-my-posh manuell installiert"
    fi

    # Themes herunterladen
    download_oh_my_posh_themes
}

download_oh_my_posh_themes() {
    local themes_dir="$HOME/.poshthemes"

    if [ -d "$themes_dir" ] && [ -f "$themes_dir/atomic.omp.json" ]; then
        print_success "Oh My Posh Themes bereits vorhanden"
    else
        print_info "Lade Oh My Posh Themes herunter..."
        mkdir -p "$themes_dir"

        wget -q --show-progress https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip -O /tmp/oh-my-posh-themes.zip

        print_info "Entpacke Themes..."
        unzip -q -o /tmp/oh-my-posh-themes.zip -d "$themes_dir"
        rm /tmp/oh-my-posh-themes.zip

        print_success "Oh My Posh Themes heruntergeladen (inkl. atomic.omp.json)"
    fi
}

# Hauptinstallation
install_system_packages() {
    print_header "System-Pakete installieren"

    print_info "Aktualisiere Package Liste..."
    sudo pacman -Sy

    # 1. Build-Tools
    print_header "Build-Tools installieren"
    local build_tools=(
        "git"
        "base-devel"
        "clang"
        "gcc"
        "cmake"
        "pkg-config"
        "wget"
        "curl"
        "tar"
        "unzip"
        "perl"
        "cpanminus"
    )

    for pkg in "${build_tools[@]}"; do
        install_if_missing "$pkg"
    done

    # 2. pyenv Dependencies (für Python-Kompilierung)
    print_header "pyenv Dependencies installieren"
    local pyenv_deps=(
        "openssl"
        "zlib"
        "xz"
        "tk"
        "libffi"
        "sqlite"
        "readline"
        "bzip2"
    )

    for dep in "${pyenv_deps[@]}"; do
        install_if_missing "$dep"
    done

    # 3. Installiere pyenv (bevorzugt aus Repo)
    install_pyenv

    # 4. Setup Python 3.12.x mit pyenv
    setup_python_with_pyenv

    # 5. Installiere pipx (für systemweite Python CLI Tools)
    install_pipx

    # 6. Andere Programmiersprachen
    print_header "Programmiersprachen installieren"

    # C/C++ (bereits durch gcc/clang installiert)
    print_success "C/C++ Compiler bereits installiert (gcc, clang)"

    # Ruby
    install_if_missing "ruby"

    # Rust
    install_if_missing "rust"

    # Go
    install_if_missing "go"

    # C#
    install_if_missing "dotnet-sdk"
    install_if_missing "aspnet-runtime"  # optional, falls du Webentwicklung willst
    install_if_missing "dotnet-runtime"   # optional, falls du nur .NET Apps laufen lassen willst

    # 7. Java Setup
    setup_java

    # 8. System-Libraries
    print_header "System-Libraries installieren"
    local libs=(
        "libxml2"
        "libxslt"
    )

    for lib in "${libs[@]}"; do
        install_if_missing "$lib"
    done

    # 9. Shells
    print_header "Shells installieren"
    install_if_missing "zsh"
    install_if_missing "nushell"

    # 10. CLI Tools
    print_header "CLI Tools installieren"
    local cli_tools=(
        "ripgrep"
        "fd"
        "fzf"
        "bat"
        "eza"
        "tmux"
        "ranger"
        "yazi"
        "zoxide"
    )

    for tool in "${cli_tools[@]}"; do
        install_if_missing "$tool"
    done

    # 11. Python Tools via pipx (systemweit, versionsunabhängig)
    print_header "Python CLI Tools installieren (via pipx)"

    if command_exists pipx; then
        # jrnl - Journaling Tool
        install_via_pipx "jrnl"

        # Poetry - Dependency Management (optional, aber nützlich)
        # install_via_pipx "poetry"

        # Python LSP Tools für Editoren
        install_python_lsp_tools
    else
        print_warning "pipx nicht verfügbar, überspringe Python CLI Tools"
    fi

    # 12. Oh My Posh (bevorzugt aus Repo)
    install_oh_my_posh

    # LuaRocks
    install_if_missing "luarocks"
}

# Verifiziere PATH Eintrag
verify_path_in_file() {
    local file=$1
    local path_pattern=$2
    local description=$3

    if [ ! -f "$file" ]; then
        print_warning "$file existiert nicht"
        return 1
    fi

    if grep -q "$path_pattern" "$file" 2>/dev/null; then
        print_success "$description in $file gefunden"
        return 0
    else
        print_warning "$description in $file NICHT gefunden"
        return 1
    fi
}

# Setup PATH für Nushell
setup_path_nushell() {
    print_header "Nushell konfigurieren"

    if ! command_exists nu; then
        print_warning "Nushell nicht installiert, überspringe"
        return
    fi

    local nu_dir="$HOME/.config/nushell"
    local env_file="$nu_dir/env.nu"
    local config_file="$nu_dir/config.nu"

    mkdir -p "$nu_dir"
    [ ! -f "$env_file" ] && touch "$env_file"
    [ ! -f "$config_file" ] && touch "$config_file"

    ##############################
    #       PYENV SETUP
    ##############################
    if ! grep -q "pyenv init" "$env_file" 2>/dev/null; then
        print_info "Füge pyenv Init zu Nushell hinzu..."
        cat >> "$env_file" << 'EOF'

# pyenv
$env.PYENV_ROOT = $"($env.HOME)/.pyenv"
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.PYENV_ROOT)/bin")
EOF
        print_success "pyenv Init hinzugefügt"
    fi

    ##############################
    #       GO PATH
    ##############################
    if ! grep -q "go/bin" "$env_file" 2>/dev/null; then
        print_info "Füge Go PATH zu Nushell hinzu..."
        cat >> "$env_file" << 'EOF'

# Go Path
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/go/bin")
EOF
        print_success "Go PATH hinzugefügt"
    fi

    ##############################
    #     RUBY GEM PATH
    ##############################
    if command_exists ruby; then
        local ruby_version=$(ruby -e 'v=RUBY_VERSION.split("."); puts "#{v[0]}.#{v[1]}.0"')

        if ! grep -q ".local/share/gem/ruby" "$env_file" 2>/dev/null; then
            print_info "Füge Ruby Gems PATH zu Nushell hinzu..."
            cat >> "$env_file" << EOF

# Ruby Gems Path (USER + System)
\$env.PATH = (\$env.PATH | split row (char esep) | prepend \$"(\$env.HOME)/.local/share/gem/ruby/${ruby_version}/bin")
EOF
            print_success "Ruby Gem PATH hinzugefügt"
        fi
    fi

    ##############################
    #  PYTHON PATHS (User + pipx)
    ##############################
    if ! grep -q "Python.*PATH" "$env_file" 2>/dev/null; then
        print_info "Füge Python User PATH zu Nushell hinzu..."
        cat >> "$env_file" << 'EOF'

# Python User Path (pipx)
$env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.local/bin")
EOF
        print_success "Python User PATH hinzugefügt"
    fi

    ##############################
    # ZOXIDE
    ##############################
    if command_exists zoxide; then
        # Nushell
        print_info "Erzeuge zoxide Init-Datei für Nushell..."
        nu -c 'zoxide init nushell | save -f "~/.config/nushell/zoxide.nu"'

        if ! grep -Fxq "source ~/.config/nushell/zoxide.nu" "$config_file"; then
            echo "" >> "$config_file"
            echo "source ~/.config/nushell/zoxide.nu" >> "$config_file"
            print_success "Zoxide für Nushell konfiguriert"
        fi
    fi

    ##############################
    # Oh My Posh
    ##############################
    if command_exists oh-my-posh; then
        if ! grep -q "oh-my-posh init" "$config_file" 2>/dev/null; then
            print_info "Konfiguriere Oh My Posh für Nushell..."
            cat >> "$config_file" << 'EOF'

# Oh My Posh Prompt
oh-my-posh init nu --config ~/.poshthemes/atomic.omp.json
EOF
            print_success "Oh My Posh konfiguriert"
        fi
    fi

    ##############################
    # VERIFIZIERUNG
    ##############################
    print_info "Verifiziere Nushell Konfiguration..."
    verify_path_in_file "$env_file" "PYENV_ROOT" "pyenv"
    verify_path_in_file "$env_file" "go/bin" "Go PATH"
    verify_path_in_file "$config_file" "oh-my-posh init" "Oh My Posh"
}

setup_path_zsh() {
    print_header "Zsh konfigurieren"

    if ! command_exists zsh; then
        print_warning "Zsh nicht installiert, überspringe"
        return
    fi

    local zshrc="$HOME/.zshrc"
    [ ! -f "$zshrc" ] && touch "$zshrc"

    ##############################
    # pyenv
    ##############################
    if ! grep -q "pyenv init" "$zshrc" 2>/dev/null; then
        print_info "Füge pyenv Init zu .zshrc hinzu..."
        cat >> "$zshrc" << 'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
        print_success "pyenv Init hinzugefügt"
    fi

    ##############################
    # Go PATH
    ##############################
    if ! grep -q "go/bin" "$zshrc" 2>/dev/null; then
        print_info "Füge Go PATH zu .zshrc hinzu..."
        cat >> "$zshrc" << 'EOF'

# Go Path
export PATH="$HOME/go/bin:$PATH"
EOF
        print_success "Go PATH hinzugefügt"
    fi

    ##############################
    # Ruby PATHs (User + System)
    ##############################
    if command_exists ruby; then
        # Ruby-Version normalisieren zu X.Y.0
        local ruby_version=$(ruby -e 'v=RUBY_VERSION.split("."); puts "#{v[0]}.#{v[1]}.0"')

        if ! grep -q ".local/share/gem/ruby" "$zshrc" 2>/dev/null; then
            print_info "Füge Ruby PATHs zu .zshrc hinzu..."
            cat >> "$zshrc" << EOF

# Ruby Gems Path (User)
user_ruby_bin="\$HOME/.local/share/gem/ruby/${ruby_version}/bin"
[[ ":\$PATH:" != *":\$user_ruby_bin:"* ]] && PATH="\$user_ruby_bin:\$PATH"

# System Gems
system_ruby_bin="/usr/bin"
[[ ":\$PATH:" != *":\$system_ruby_bin:"* ]] && PATH="\$system_ruby_bin:\$PATH"

EOF
            print_success "Ruby PATHs hinzugefügt"
        fi
    fi


    ##############################
    # Python PATHs (User + System + pipx)
    ##############################
    if ! grep -q "Python PATHs" "$zshrc" 2>/dev/null; then
        print_info "Füge Python PATHs zu .zshrc hinzu..."
        cat >> "$zshrc" << 'EOF'

# Python PATHs
# User pipx / pip --user
user_python_bin="$HOME/.local/bin"
[[ ":$PATH:" != *":$user_python_bin:"* ]] && PATH="$user_python_bin:$PATH"

# System Python
system_python_bin="/usr/bin"
[[ ":$PATH:" != *":$system_python_bin:"* ]] && PATH="$system_python_bin:$PATH"
EOF
        print_success "Python PATHs hinzugefügt"
    fi

    ##############################
    # Zoxide
    ##############################
    if command_exists zoxide; then
        if command_exists zsh; then
            local zoxide_zsh_file="$HOME/.zoxide.zsh"
            local zshrc_file="$HOME/.zshrc"
            print_info "Erzeuge zoxide Init-Datei für Zsh..."
            zoxide init zsh > "$zoxide_zsh_file"

            if ! grep -Fxq "source ~/.zoxide.zsh" "$zshrc_file" 2>/dev/null; then
                echo "" >> "$zshrc_file"
                echo "source ~/.zoxide.zsh" >> "$zshrc_file"
                print_success "Zoxide erfolgreich für Zsh konfiguriert"
            fi
        fi
    fi

    ##############################
    # Verifizierung
    ##############################
    verify_path_in_file "$zshrc" "pyenv init" "pyenv"
    verify_path_in_file "$zshrc" "go/bin" "Go PATH"
    verify_path_in_file "$zshrc" ".gem/ruby" "Ruby PATH"
    verify_path_in_file "$zshrc" ".local/bin" "Python User PATH"
}


# Setup PATH für Bash
setup_path_bash() {
    print_header "Bash konfigurieren"

    local bashrc="$HOME/.bashrc"
    [ ! -f "$bashrc" ] && touch "$bashrc"

    ##############################
    # pyenv
    ##############################
    if ! grep -q "pyenv init" "$bashrc" 2>/dev/null; then
        print_info "Füge pyenv Init zu .bashrc hinzu..."
        cat >> "$bashrc" << 'EOF'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
        print_success "pyenv Init hinzugefügt"
    fi

    ##############################
    # Go PATH
    ##############################
    if ! grep -q "go/bin" "$bashrc" 2>/dev/null; then
        print_info "Füge Go PATH zu .bashrc hinzu..."
        cat >> "$bashrc" << 'EOF'

# Go Path
export PATH="$HOME/go/bin:$PATH"
EOF
        print_success "Go PATH hinzugefügt"
    fi

    ##############################
    # Ruby PATHs (User + System)
    ##############################
    if command_exists ruby; then
        # Ruby-Version normalisieren zu X.Y.0
        local ruby_version=$(ruby -e 'v=RUBY_VERSION.split("."); puts "#{v[0]}.#{v[1]}.0"')

        if ! grep -q ".local/share/gem/ruby" "$bashrc" 2>/dev/null; then
            print_info "Füge Ruby PATHs zu .bashrc hinzu..."
            cat >> "$bashrc" << EOF

# Ruby Gems Path (User)
user_ruby_bin="\$HOME/.local/share/gem/ruby/${ruby_version}/bin"
[[ ":\$PATH:" != *":\$user_ruby_bin:"* ]] && export PATH="\$user_ruby_bin:\$PATH"

# System Gems
system_ruby_bin="/usr/bin"
[[ ":\$PATH:" != *":\$system_ruby_bin:"* ]] && export PATH="\$system_ruby_bin:\$PATH"

EOF
            print_success "Ruby PATHs hinzugefügt"
        fi
    fi


    ##############################
    # Python PATHs (User + System + pipx)
    ##############################
    if ! grep -q "Python PATHs" "$bashrc" 2>/dev/null; then
        print_info "Füge Python PATHs zu .bashrc hinzu..."
        cat >> "$bashrc" << 'EOF'

# Python PATHs
# User pipx / pip --user
user_python_bin="$HOME/.local/bin"
[[ ":$PATH:" != *":$user_python_bin:"* ]] && export PATH="$user_python_bin:$PATH"

# System Python
system_python_bin="/usr/bin"
[[ ":$PATH:" != *":$system_python_bin:"* ]] && export PATH="$system_python_bin:$PATH"
EOF
        print_success "Python PATHs hinzugefügt"
    fi

    ##############################
    # Zoxide
    ##############################
    if command_exists zoxide; then
        if ! grep -q "eval.*zoxide" "$bashrc" 2>/dev/null; then
            print_info "Konfiguriere zoxide für Bash..."
            cat >> "$bashrc" << 'EOF'

# Zoxide (Smart cd)
eval "$(zoxide init bash)"
EOF
            print_success "Zoxide konfiguriert"
        fi
    fi

    ##############################
    # Verifizierung
    ##############################
    verify_path_in_file "$bashrc" "pyenv init" "pyenv"
    verify_path_in_file "$bashrc" "go/bin" "Go PATH"
    verify_path_in_file "$bashrc" ".gem/ruby" "Ruby PATH"
    verify_path_in_file "$bashrc" ".local/bin" "Python User PATH"
}

# tmux + TPM Setup
setup_tmux() {
    print_header "tmux + TPM (Plugin Manager) installieren"

    # Prüfen, ob tmux installiert ist
    if ! command_exists tmux; then
        print_warning "tmux nicht gefunden — bitte zuerst tmux installieren"
        return 1
    fi

    # Verzeichnis für Plugins vorbereiten
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm_dir" ]; then
        print_info "Klonen von tmux-plugin-manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm.git "$tpm_dir"
        if [ $? -ne 0 ]; then
            print_error "Fehler beim Klonen von TPM"
            return 1
        fi
        print_success "TPM geklont"
    else
        print_info "TPM bereits vorhanden"
    fi

    # tmux Config anpassen: ~/.tmux.conf oder $XDG_CONFIG_HOME/tmux/tmux.conf
    local tmux_conf_file="$HOME/.tmux.conf"
    [ -n "$XDG_CONFIG_HOME" ] && tmux_conf_file="$XDG_CONFIG_HOME/tmux/tmux.conf"
    mkdir -p "$(dirname "$tmux_conf_file")"
    if [ ! -f "$tmux_conf_file" ]; then
        touch "$tmux_conf_file"
    fi

    # Sicherstellen, dass die TPM-Einträge nicht doppelt sind
    if ! grep -q "tmux-plugins/tpm" "$tmux_conf_file"; then
        print_info "Füge TPM-Konfiguration zu $tmux_conf_file hinzu..."
        cat >> "$tmux_conf_file" << 'EOF'
# ~/.tmux.conf

# =============================================
# Neovim Integration
# =============================================

# True Color Support
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Neovim Escape-Delay fix (wichtig!)
set -sg escape-time 10

# Focus Events (für Neovim Auto-Reload)
set -g focus-events on

# =============================================
# Vim-Tmux-Navigator (Smart Pane Switching)
# =============================================
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

# Tmux Version < 3.0
# bind-key -n 'C-\' if-shell "$is_vim" 'send-keys C-\\'  'select-pane -l'

# Copy Mode Vim-Style
bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
# bind-key -T copy-mode-vi 'C-\' select-pane -l

# =============================================
# Vim-Style Copy Mode
# =============================================
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

# =============================================
# Bessere Prefix-Key (optional)
# =============================================
# Uncomment wenn du Ctrl-a statt Ctrl-b willst
# unbind C-b
# set -g prefix C-a
# bind C-a send-prefix

# =============================================
# Pane Splitting (intuitiver)
# =============================================
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# =============================================
# Mouse Support
# =============================================
set -g mouse on

# =============================================
# Statusline (optional - schöner)
# =============================================
set -g status-position bottom
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left ''
set -g status-right '#[fg=#f38ba8,bold] %H:%M '
set -g status-right-length 50
set -g status-left-length 20

setw -g window-status-current-style 'fg=#1e1e2e bg=#89b4fa bold'
setw -g window-status-current-format ' #I:#W#F '

setw -g window-status-style 'fg=#cdd6f4'
setw -g window-status-format ' #I:#W#F '

# =============================================
# Pane Borders
# =============================================
set -g pane-border-style 'fg=#313244'
set -g pane-active-border-style 'fg=#89b4fa'

# =============================================
# Pane Index starting with 1
# =============================================
# Start Windows und Panes bei Index 1
set -g base-index 1

# Fenster beim Umbenennen automatisch neu nummerieren
set-option -g renumber-windows on

# =============================================
# Plugins
# =============================================
# —— TPM (Tmux Plugin Manager) ——
set -g @plugin 'tmux-plugins/tpm'

set -g @plugin 'tmux-plugins/tmux-sensible'

# Themes
# set -g @plugin 'catppucin/tmux'
set -g @plugin 'dreamsofcode-io/catppuccin-tmux'

# Yank enables to cpy with Y-key
set -g @plugin 'tmux-plugins/tmux-yank'

# TPM initialisieren — immer am Ende der Config
run '~/.tmux/plugins/tpm/tpm'

EOF
        print_success "TPM-Konfiguration hinzugefügt"
    else
        print_info "TPM-Einträge bereits in tmux.conf vorhanden"
    fi

    print_success "setup_tmux abgeschlossen — starte tmux und drücke <prefix> + I um Plugins zu installieren"
}


# Verifiziere Installationen
verify_installations() {
    print_header "Verifiziere Installationen"

    echo ""
    print_info "Programmiersprachen:"

    # C/C++
    if command_exists gcc; then
        print_success "C/C++ (gcc): $(gcc --version | head -n1)"
    else
        print_warning "gcc nicht gefunden"
    fi

    if command_exists clang; then
        print_success "C/C++ (clang): $(clang --version | head -n1)"
    else
        print_warning "clang nicht gefunden"
    fi

    # Python
    if command_exists python; then
        print_success "Python: $(python --version)"
    else
        print_warning "python nicht gefunden"
    fi

    # pipx
    if command_exists pipx; then
        print_success "pipx: $(pipx --version)"
    else
        print_warning "pipx nicht gefunden"
    fi

    # Ruby
    if command_exists ruby; then
        print_success "Ruby: $(ruby --version | cut -d' ' -f1-2)"
    else
        print_warning "ruby nicht gefunden"
    fi

    # Rust
    if command_exists rustc; then
        print_success "Rust: $(rustc --version)"
    else
        print_warning "rustc nicht gefunden"
    fi

    # Go
    if command_exists go; then
        print_success "Go: $(go version | cut -d' ' -f3-4)"
    else
        print_warning "go nicht gefunden"
    fi

    # Java
    if command_exists java; then
        print_success "Java: $(java -version 2>&1 | head -n1)"
    else
        print_warning "java nicht gefunden"
    fi

    echo ""
    print_info "Shells:"

    if command_exists bash; then
        print_success "Bash: $(bash --version | head -n1 | cut -d' ' -f4)"
    fi

    if command_exists zsh; then
        print_success "Zsh: $(zsh --version)"
    else
        print_warning "zsh nicht gefunden"
    fi

    if command_exists nu; then
        print_success "Nushell: $(nu --version)"
    else
        print_warning "nushell nicht gefunden"
    fi

    echo ""
    print_info "CLI Tools:"

    local tools=("ripgrep:rg" "fd" "fzf" "bat" "eza" "tmux" "ranger" "zoxide" "oh-my-posh")

    for tool in "${tools[@]}"; do
        local cmd="${tool%%:*}"
        local check_cmd="${tool##*:}"
        [ "$cmd" = "$tool" ] && check_cmd="$cmd"

        if command_exists "$check_cmd"; then
            print_success "$cmd ✓"
        else
            print_warning "$cmd nicht gefunden"
        fi
    done

    echo ""
    print_info "Python Tools (pipx):"

    local pipx_tools=("jrnl" "ruff-lsp" "python-lsp-server")

    for tool in "${pipx_tools[@]}"; do
        if command_exists "$tool" || (command_exists pipx && pipx list 2>/dev/null | grep -q "$tool"); then
            print_success "$tool ✓"
        else
            print_warning "$tool nicht gefunden"
        fi
    done

    echo ""
}

# Hauptprogramm
main() {
    print_header "Dev Environment Setup für Manjaro/Arch"

    # Prüfe System
    if [ ! -f "/etc/manjaro-release" ] && [ ! -f "/etc/arch-release" ]; then
        print_error "Dieses Script ist nur für Manjaro/Arch Linux!"
        exit 1
    fi

    print_success "System erkannt: Manjaro/Arch Linux"

    # Installation
    install_system_packages

    # Shell Konfiguration
    setup_path_bash
    setup_path_zsh
    setup_path_nushell

    setup_tmux

    # Verifiziere
    verify_installations

    # Finale Nachricht
    print_header "Installation abgeschlossen!"
    echo ""
    print_success "Alle Komponenten wurden installiert"
    echo ""
    print_info "Wichtige Hinweise:"
    echo "  - Python Version: 3.12.x (stabile LTS-ähnliche Version)"
    echo "  - Pakete bevorzugt aus Manjaro/Arch Repos installiert"
    echo "  - Python CLI Tools via pipx (versionsunabhängig)"
    echo ""
    print_info "Nächste Schritte:"
    echo "  1. Shell neu starten oder Config neu laden:"
    echo "     - Bash:    source ~/.bashrc"
    echo "     - Zsh:     source ~/.zshrc"
    echo "     - Nushell: exec nu  (oder Terminal neu starten)"
    echo ""
    echo "  2. Nushell mit Oh My Posh testen:"
    echo "     nu"
    echo "     (Der atomic Theme Prompt sollte erscheinen)"
    echo ""
    echo "  3. Zoxide testen:"
    echo "     z --help"
    echo ""
    echo "  4. pipx Tools verwalten:"
    echo "     pipx list              # Alle installierten Tools anzeigen"
    echo "     pipx upgrade-all       # Alle Tools aktualisieren"
    echo "     pipx install <tool>    # Neues Tool installieren"
    echo ""
    print_info "Installierte Programmiersprachen:"
    echo "  - C/C++:  gcc, clang"
    echo "  - Python: pyenv → 3.12.x ($(python --version 2>/dev/null || echo 'nicht im PATH'))"
    echo "  - Ruby:   $(ruby --version 2>/dev/null | cut -d' ' -f1-2 || echo 'nicht installiert')"
    echo "  - Rust:   $(rustc --version 2>/dev/null || echo 'nicht installiert')"
    echo "  - Go:     $(go version 2>/dev/null | cut -d' ' -f3 || echo 'nicht installiert')"
    echo "  - Java:   archlinux-java ($(java -version 2>&1 | head -n1 || echo 'nicht konfiguriert'))"
    echo ""
    print_info "CLI Tools:"
    echo "  - zoxide:  Smart cd (nutze 'z' statt 'cd')"
    echo "  - ripgrep: Schnelle Suche (rg)"
    echo "  - fd:      Schnelle Dateisuche"
    echo "  - fzf:     Fuzzy Finder"
    echo "  - bat:     Besseres cat"
    echo "  - eza:     Besseres ls"
    echo "  - tmux:    Terminal Multiplexer"
    echo "  - ranger:  Dateimanager"
    echo "  - yazi:    Dateimanager"
    echo "  - jrnl:    Journaling Tool"
    echo ""
    print_info "Oh My Posh Theme:"
    echo "  - Theme-Ordner: ~/.poshthemes/"
    echo "  - Aktives Theme: atomic.omp.json"
    echo "  - Andere Themes: ls ~/.poshthemes/"
    echo ""
}

# Script ausführen
main "$@"
