#!/bin/bash
set -euo pipefail

## Arguments!!
SERVICE_FILE=${SERVICE_FILE:-currentu-pochino.service}
LISTENER_FILE=${LISTENER_FILE:-pochino_listener.py}
ON_SCRIPT=${ON_SCRIPT:-on.sh}
OFF_SCRIPT=${OFF_SCRIPT:-off.sh}
SERIAL_PATH=${SERIAL_PATH:-""}

usage() {
  echo "Usage: $0 [-s service_file] [-l listener_file] [-o on_script] [-f off_script] [-d serial_path]"
  exit 1
}

while getopts "s:l:o:f:d:h" opt; do
  case "$opt" in
    s) SERVICE_FILE=$OPTARG ;;
    l) LISTENER_FILE=$OPTARG ;;
    o) ON_SCRIPT=$OPTARG ;;
    f) OFF_SCRIPT=$OPTARG ;;
    d) SERIAL_PATH=$OPTARG ;;
    h|*) usage ;;
  esac
done

if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This script must be run as root." >&2
    exit 1
fi

if [[ ! -f $LISTENER_FILE ]]; then
    echo "Error: $LISTENER_FILE missing in current directory!" >&2
    exit 2
fi

if [[ ! -f $ON_SCRIPT || ! -f $OFF_SCRIPT ]]; then
    echo "On/Off action scripts missing in current directory!"
    echo "If you wish to proceed without them, you must edit the default listener script to not use them!"
    read -rp "Continue? (y/N) " CONTINUE_INSTALL
    if [[ "$CONTINUE_INSTALL" != "y" && "$CONTINUE_INSTALL" != "Y" ]]; then
        echo "Aborting installation."
        exit 1
    fi
fi

if [[ -z "$SERIAL_PATH" ]]; then
    echo "No serial path provided, launching detection script..."
    source ./usb_detect.sh
    if [[ -z "$SERIAL_PATH" ]]; then
        echo "Error: No serial path detected after script execution!" >&2
        exit 1
    fi
    echo "Using detected serial path: $SERIAL_PATH"
else
    echo "Using provided serial path: $SERIAL_PATH"
fi

echo "Installing listener..."
install -m 755 $LISTENER_FILE /usr/local/bin/pochino_listener.py

if [[ -f $ON_SCRIPT || -f $OFF_SCRIPT ]]; then
    echo "Installing action scripts..."
    install -d -m 755 /usr/local/lib/currentu-pochino
    [[ -f $ON_SCRIPT ]] && install -m 754 $ON_SCRIPT  /usr/local/lib/currentu-pochino/on.sh
    [[ -f $OFF_SCRIPT ]] && install -m 754 $OFF_SCRIPT /usr/local/lib/currentu-pochino/off.sh
fi

INSTALL_SERVICE="N"
[[ -f $SERVICE_FILE ]] && read -rp "Do you want to install the systemd service to manage the listener? (Y/n) " INSTALL_SERVICE
if [[ "$INSTALL_SERVICE" == "n" || "$INSTALL_SERVICE" == "N" ]]; then
    echo "Skipping service installation. You can set up the service manually later."
else
    echo "Installing systemd service..."

    DEVICE_UNIT=$(systemd-escape -p --suffix=device "$SERIAL_PATH")
    TMP_UNIT=$(mktemp)
    sed -e "s|^Requires=.*|Requires=$DEVICE_UNIT|" \
        -e "s|^After=.*|After=$DEVICE_UNIT|" \
        -e "s|^User=.*|User=$(logname)|" \
        -e "s|^Environment=ARDUINO_SERIAL_PATH=.*|Environment=ARDUINO_SERIAL_PATH=$SERIAL_PATH|" \
        "$SERVICE_FILE" > "$TMP_UNIT" 
    install -m 644 "$TMP_UNIT" /etc/systemd/system/currentu-pochino.service
    rm -f "$TMP_UNIT"

    systemctl daemon-reload
    systemctl enable currentu-pochino.service
    systemctl restart currentu-pochino.service

    systemctl status currentu-pochino.service --no-pager
fi

echo "Installation completed!"

