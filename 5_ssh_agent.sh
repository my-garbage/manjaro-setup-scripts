#!/usr/bin/env bash
# ========================================================
# Script: setup-ssh-agent-git-keys.sh
# Ziel: systemd ssh-agent aktivieren und alle SSH-Keys mit passenden .pub-Dateien automatisch laden
# für Manjaro Linux (bash/zsh)
# ========================================================

# Shell Configs
ZSHRC="$HOME/.zshrc"
BASHRC="$HOME/.bashrc"

# ========================================================
# 1️⃣ systemd ssh-agent aktivieren/starten
# ========================================================
function enable_systemd_agent() {
    if ! systemctl --user is-enabled ssh-agent &>/dev/null; then
        echo "[INFO] Aktivieren von systemd ssh-agent..."
        systemctl --user enable ssh-agent
    else
        echo "[INFO] systemd ssh-agent ist bereits aktiviert."
    fi

    if ! systemctl --user is-active ssh-agent &>/dev/null; then
        echo "[INFO] Starten von systemd ssh-agent..."
        systemctl --user start ssh-agent
    else
        echo "[INFO] systemd ssh-agent läuft bereits."
    fi
}

# ========================================================
# 2️⃣ SSH_AUTH_SOCK exportieren (falls noch nicht in Shell-Config)
# ========================================================
function ensure_socket_export() {
    FILES=("$ZSHRC" "$BASHRC")
    for FILE in "${FILES[@]}"; do
        if [[ -f "$FILE" ]]; then
            if ! grep -q "export SSH_AUTH_SOCK=" "$FILE"; then
                echo "[INFO] Füge SSH_AUTH_SOCK export in $FILE ein..."
                echo -e "\n# SSH-Agent Socket automatisch setzen\nexport SSH_AUTH_SOCK=\"\$XDG_RUNTIME_DIR/ssh-agent.socket\"" >> "$FILE"
            else
                echo "[INFO] SSH_AUTH_SOCK export bereits in $FILE vorhanden."
            fi
        fi
    done
}

# ========================================================
# 3️⃣ Nur private Keys laden, für die es ein .pub gibt
# ========================================================
function add_ssh_keys_with_pub() {
    SSH_DIR="$HOME/.ssh"
    if [[ ! -d "$SSH_DIR" ]]; then
        echo "[WARN] Kein ~/.ssh Verzeichnis gefunden."
        return
    fi

    # Schleife über alle privaten Keys
    for key in "$SSH_DIR"/*; do
        # Prüfen: existiert die .pub Datei?
        if [[ -f "$key" && ! "$key" =~ \.pub$ && -f "$key.pub" ]]; then
            key_fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
            if ! ssh-add -l 2>/dev/null | grep -q "$key_fingerprint"; then
                echo "[INFO] Füge SSH Key hinzu: $key"
                ssh-add "$key" 2>/dev/null
            else
                echo "[INFO] SSH Key bereits geladen: $key"
            fi
        fi
    done
}

# ========================================================
# Hauptprogramm
# ========================================================
echo "[START] SSH-Agent Setup prüfen..."

enable_systemd_agent
ensure_socket_export
add_ssh_keys_with_pub

echo "[DONE] SSH-Agent Setup abgeschlossen."
echo "Bitte neue Shell starten oder source ~/.zshrc bzw ~/.bashrc ausführen."
