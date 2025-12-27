#!/bin/bash
# MIT License - see LICENSE file for details.
# Copyright (c) 2025 Ilamparithi Murali

retry_prompt() {
    echo "Let's retry this shall we?"
    echo "Press Ctrl+C to quit anytime"
    echo "-----------------------------------"
    echo
    SERIAL_PATH=""
    sleep 0.5
}

SERIAL_PATH=""
while true; do
    # Find the ino's by-id path
    echo "Preparing to detect the Arduino..."
    echo "Please disconnect your Arduino if it is connected, then press Enter"
    read -r
    BEFORE_USB=$(lsusb | sort)
    BEFORE_BYID=$(ls /dev/serial/by-id 2>/dev/null | sort)
    BEFORE_TTY=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | sort)
    sleep 0.25

    echo "Now connect *just* your Arduino and press Enter. I'll wait!"
    read -r
    sleep 1
    AFTER_USB=$(lsusb | sort)
    AFTER_BYID=$(ls /dev/serial/by-id 2>/dev/null | sort)
    AFTER_TTY=$(ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null | sort)

    # Find the new device (lsusb) and new by-id link (stable path)
    NEW_USB=$(comm -13 <(echo "$BEFORE_USB") <(echo "$AFTER_USB"))
    NEW_BYID=$(comm -13 <(echo "$BEFORE_BYID") <(echo "$AFTER_BYID"))
    NEW_TTY=$(comm -13 <(echo "$BEFORE_TTY") <(echo "$AFTER_TTY"))

    if [[ -z "$NEW_USB" ]]; then
        echo "No new USB device detected!"
        retry_prompt
        continue
    fi

    echo "Detected: $NEW_USB"
    echo "Serial path detected: ${NEW_BYID:-None}"
    if [[ -z "$NEW_BYID" ]]; then
        if [[ -z "$NEW_TTY" ]]; then
            echo "The detected device does not have a serial port..."
            sleep 2
            retry_prompt
            continue
        else
            echo "Serial path was not found but TTY path was found."
            echo "Using this path may not be stable across reboots."
            read -rp "Do you want to use $NEW_TTY as the serial path? (y/N) " USE_TTY
            if [[ "$USE_TTY" != "y" && "$USE_TTY" != "Y" ]]; then
                retry_prompt
                continue
            fi
            
            SERIAL_PATH="$NEW_TTY"
        fi
    else
        SERIAL_PATH="/dev/serial/by-id/$NEW_BYID"
    fi
    sleep 0.2
    echo
    read -rp "Is this your Arduino? (y/N) " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        retry_prompt
        continue
    else
        echo "Great! Proceeding..."
        break
    fi
done