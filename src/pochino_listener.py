import serial
import subprocess
import glob
import time
import sys
import os

from serial.serialutil import SerialException

"""Use setup script to automatically set this up in the service's unit file!"""
SERIAL_PATH = os.getenv("ARDUINO_SERIAL_PATH")  # e.g., "/dev/serial/by-id/usb-1a86_USB2.0-Serial-if00-port0" or "/dev/ttyUSB0"

ON_SCRIPT = "/usr/local/lib/currentu-pochino/on.sh"
OFF_SCRIPT = "/usr/local/lib/currentu-pochino/off.sh"

"""Unused function left for testing"""
def open_serial() -> serial.Serial:
    ports = glob.glob("/dev/serial/by-id/usb-1a86_*")
    if not ports:
        raise RuntimeError("Arduino not found")
    return serial.Serial(ports[0], 115200, timeout=15)


def exit_with_error(message: str, code: int) -> None:
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(code)


while True:
    try:
        try:
            ser = serial.Serial(SERIAL_PATH, 115200, timeout=1)
        except SerialException as e:
            error_text = str(e)
            if (getattr(e, "errno", None) == 2) or "could not open port" in error_text:
                exit_with_error(
                    f"Unable to open serial port '{SERIAL_PATH}': {error_text}",
                    67,
                )

        while True:
            try:
                line = ser.readline().decode(errors="ignore").strip()
            except SerialException as e:
                error_text = str(e)
                if "device reports readiness to read but returned no data" in error_text:
                    exit_with_error(
                        f"Serial device disconnected or grabbed elsewhere ({error_text}); exiting.",
                        3,
                    )
            """
            Customize this part to do whatever you want with the input, which can be:
            - "ON": Digital Input HIGH detected
            - "OFF": Digital Input LOW detected
            - "HI": Serial Connection Initialised message
            """
            if line == "ON":
                subprocess.run([ON_SCRIPT])
            elif line == "OFF":
                subprocess.run([OFF_SCRIPT])
            elif line == "HI":
                print("Initialised, Hi!")
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        time.sleep(15)
        raise
        
