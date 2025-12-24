import serial
import subprocess
import glob
import time
import sys

def open_serial():
    ports = glob.glob("/dev/serial/by-id/usb-1a86_*")
    if not ports:
        raise RuntimeError("Arduino not found")
    return serial.Serial(ports[0], 115200, timeout=15)

while True:
    try:
        ser = open_serial()

        while True:
            line = ser.readline().decode(errors="ignore").strip()
            if line == "ON":
                print("ON")
            elif line == "OFF":
                print("OFF")
            elif line == "HI":
                print("Initialised, Hi!")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        time.sleep(15)
        raise
        
