#!/bin/bash
set -euo pipefail

SERVICE_FILE=currentu-pochino.service
LISTENER_FILE=arduino_listener.py
ON_SCRIPT=on.sh
OFF_SCRIPT=off.sh


if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

if [[ ! -f $LISTENER_FILE ]]; then
    echo "Error: $LISTENER_FILE missing in current directory!" >&2
    exit 2
fi

if [[ ! -f $ON_SCRIPT || ! -f $OFF_SCRIPT ]]; then
    echo "Error: on/off script missing in current directory!" >&2
    exit 2
fi

if [[ ! -f $SERVICE_FILE ]]; then
    echo "Error: systemd unit file missing!" >&2
    exit 2
fi

# TODO: Use prompt to select usb by-id string

echo "Installing listener..."
install -m 755 $LISTENER_FILE /usr/local/bin/arduino_listener.py

echo "Installing action scripts..."
install -d -m 755 /usr/local/lib/currentu-pochino
install -m 755 $ON_SCRIPT  /usr/local/lib/currentu-pochino/on.sh
install -m 755 $OFF_SCRIPT /usr/local/lib/currentu-pochino/off.sh

# TODO: Replace identifiable information on the fly (username and stuff)

echo "Installing systemd service..."
install -m 644 $SERVICE_FILE /etc/systemd/system/currentu-pochino.service
systemctl daemon-reload
systemctl enable currentu-pochino.service
systemctl restart currentu-pochino.service

echo "Installation completed!"
systemctl status currentu-pochino.service --no-pager
