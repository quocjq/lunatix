#!/bin/bash

# Define the standard systemd user service directory and file path
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/emacs.service"

if [ -f "$SERVICE_FILE" ]; then
    echo "Emacs service file found. Restarting..."
    killall emacs && systemctl --user start emacs
else
    echo "Service file not found. Creating $SERVICE_FILE..."

    # Ensure the target directory exists
    mkdir -p "$SERVICE_DIR"

    # Write the service configuration into the file
    cat << 'EOF' > "$SERVICE_FILE"
[Unit]
Description=Emacs text editor
Documentation=info:emacs man:emacs(1) https://gnu.org/software/emacs/

[Service]
Type=forking
ExecStart=/usr/bin/emacs --daemon
ExecStop=/usr/bin/emacsclient --eval "(kill-emacs)"
Environment=SSH_AUTH_SOCK=%t/keyring/ssh
Restart=on-failure

[Install]
WantedBy=default.target
EOF

    echo "File created successfully."

    systemctl --user daemon-reload
    echo "Systemd reloaded. You can now start Emacs with: systemctl --user start emacs"
fi
