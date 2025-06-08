#!/bin/bash
# 20250608: Minor fixes.

source ./tools/config.sh

# WARNING: ESP32_ARDUINO path cannot end in "/" 20250608
if [ -z $ESP32_ARDUINO ]; then
    if [[ "$AR_OS" == "macos" ]]; then
    	ESP32_ARDUINO="$HOME/Documents/Arduino/hardware/espressif/esp32"
    else
    	ESP32_ARDUINO="$HOME/Arduino/hardware/espressif/esp32"
    fi
fi

if ! [ -d "$ESP32_ARDUINO" ]; then
	echo "ERROR: Target arduino folder does not exist!"
	exit 1
fi

echo "Installing new libraries to $ESP32_ARDUINO"

echo "Cleaning existing files first..."
rm -rf $ESP32_ARDUINO/tools/sdk $ESP32_ARDUINO/tools/gen_esp32part.py $ESP32_ARDUINO/tools/platformio-build-*.py $ESP32_ARDUINO/platform.txt

echo "Copying platform.txt"
cp -f $AR_OUT/platform.txt $ESP32_ARDUINO/

# Original version of script fails if this directory doesn't already exist
# It is expecting that you're copying to an already checked out version
# of the arduino-esp32 repository. 20250608
if [ ! -d "${ESP32_ARDUINO}/package" ]; then
	echo "Creating ${ESP32_ARDUINO}/package directory"
	mkdir "${ESP32_ARDUINO}/package"
fi

# To support copying to an empty folder, don't specify the destination
# filename. 20250608
# cp -f $AR_OUT/package_esp32_index.template.json $ESP32_ARDUINO/package/package_esp32_index.template.json
echo "Copying package_esp32_index.template.json"
cp -f $AR_OUT/package_esp32_index.template.json $ESP32_ARDUINO/package

echo "Copying sdk into destination tools folder (will create if it doesn't exist yet)"
cp -Rf $AR_TOOLS/sdk $ESP32_ARDUINO/tools/

echo "Copying gen_esp32part.py to tools folder"
cp -f $AR_TOOLS/gen_esp32part.py $ESP32_ARDUINO/tools/

echo "Copying platformio-build-*.py to tools folder"
cp -f $AR_TOOLS/platformio-build-*.py $ESP32_ARDUINO/tools/
