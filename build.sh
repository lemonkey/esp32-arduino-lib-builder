#!/bin/bash
# 20250608: Added support for customizing the commit SHA for additional dependencies besides esp-idf and arduino-esp32.
# 20250608: Also added support for specifying a specific commit SHA for arduino-esp32 to be used as the basis for building the custom version of the library.
#
# WARNING: Using `yes | ./build.sh <options` doesn't work. May still have to answer prompts during the build (can't let it run completely unattended).
#
# Examples:
#   - With esp-camera and without rainmaker: `./build.sh -I feature/fws-custom-1b16ef6cfc-4.4.2 -i 1b16ef6 -A feature/fws-custom-55d608e3-2.0.5 -x -j 5611989 -k f3006d7 -m 401faf8 -n 485a037 -o 111515a29 -c /Users/lemonkey/Source/_3rd/esp32-arduino-lib-builder/custom-arduino-esp32-build -t esp32`
#   - Without esp-camera and without rainmaker: `./build.sh -I feature/fws-custom-1b16ef6cfc-4.4.2 -i 1b16ef6 -A feature/fws-custom-55d608e3-2.0.5 -x -y -k f3006d7 -m 401faf8 -n 485a037 -o 111515a29 -c /Users/lemonkey/Source/_3rd/esp32-arduino-lib-builder/custom-arduino-esp32-build -t esp32`
#   - Without esp-camera and without rainmaker using branch and commit for arduino-esp32: `./build.sh -I feature/fws-custom-1b16ef6cfc-4.4.2 -i 1b16ef6 -A feature/fws-custom-55d608e3-2.0.5 -a 55d608e3 -x -y -k f3006d7 -m 401faf8 -n 485a037 -o 111515a29 -c /Users/lemonkey/Source/_3rd/esp32-arduino-lib-builder/custom-arduino-esp32-build -t esp32`
#   - Using path to our fork instead of local dir: `./build.sh -I feature/fws-custom-1b16ef6cfc-4.4.2 -i 1b16ef6 -A feature/fws-custom-55d608e3-2.0.5 -a b0054d2 -x -y -k f3006d7 -m 401faf8 -n 485a037 -o 111515a29 -c /Users/lemonkey/source/_3rd/arduino-esp32 -t esp32`
#
# NOTE: `b0054d2` has fixed version of platformio build script and we should use this version going forward. 20250609
#
# ################################
# About using `menuconfig`
# ################################
# See also https://mm.kno.wled.ge/advanced/compile-arduino-esp32/.
#
# Add `-b menuconfig` to configure sdkconfig as part of the build and set all the configuration options.
#
# After saving, this will create an sdkconfig in the root of esp32-arduino-lib-builder.
#
# WARNING: This file is functionally useless because the build system will use configs/defconfig.common with configs/defconfig.esp32 
# and then add your sdkconfig file - which means most of your modifications will be overwritten by the defaults and we do not want that.
#
# To get your new build to use your menuconfig created build file, change to your esp32-arduino-lib-builder folder and do:
#   `cd configs`
#   `cp defconfig.common defconfig.common.org` to make a backup
#   `cp defconfig.esp32 defconfig.esp32.org` to make a backup
#   `rm defconfig.esp32` to get rid of the S3 defaults
#   `touch defconfig.esp32` to make a blank file so nothing complains during the build
#   `cp ../sdkconfig defconfig.common` to put your options into the build file
#
# NOTE: The above can also be used to start with the version of sdkconfig we're currently using before customizing arduino-esp32 by copying
# it over the sdkconfig at the repo root before copying it over defconfig.common.
#
# WARNING: This version of sdkconfig was when it was built with esp-camera and esp-rainmaker (along with insights). Should remove 
# those settings first.
#
# WARNING: You'll still end up seeing "ESP RainMaker" config when using `-b menuconfig`. Probably harmless.
#
# Then run build.sh with the parameters you previously used, BUT WITHOUT `-b menuconfig`.
#
# This should build the ESP32 build with your options and copy it into the correct spot in /path/to/your/arduino-esp32/.
#
# There are other ways to do this, but with this method your previous choices are reflected as the default options when you run menuconfig again.
#
# NOTE: You could make a blank defconfig.common file and cp ../sdkconfig defconfig.esp32 if you want to make different board configs with menuconfig.
#
# In order to undo this if you things aren't working and you can't remember which options you changed, just:
#       `cp defconfig.common.org defconfig.common`
#       `cp defconfig.esp32.org defconfig.esp32`
#
# and then menuconfig will start with the original "sane" defaults again.
#
####################################################
# Deploying the custom built arduino-esp32 library
####################################################
# The main thing is to commit the changes made to the arduino-esp32 library to your own fork of the library.
#
# It won't be a complete mirror of the actual fork. It will only contain changes relative to what you just built (it won't have board definitions, etc.)
#
# After committing and pushing the changes to the arduino-esp32 fork, note the commit SHA and update the platform_packages entry in platformio.ini.
# 
# platform_packages =
#   framework-arduinoespressif32 @ https://github.com/lemonkey/arduino-esp32.git#55d608e3
#   board_build.arduino.upstream_packages = no
#
# WARNING: `board_build.arduino.upstream_packages = no` is important since we don't want
# PlatformIO to fetch missing libraries from the upstream Arduino library server.
# We want PlatformIO to only use the libraries provided by the specific platform it is using. 
# This can be useful if you want to isolate dependencies or have conflicts with the 
# platform-specific library versions. 
#
# NOTE: "If you change the underlying IDF version used with the custom arduino-esp32 library, ... 
# you can edit arduino-esp32/package.json with the correct version of arduino-esp32 for your IDF 
# (with IDF v4.4.6 it should be 2.0.14, for example), or whatever custom version you want it to be."
#
# You can figure out the IDF to arduino-esp32 version mapping by looking thru https://github.com/espressif/arduino-esp32/releases 
# if you really want everything to be correct, even if it doesn't actually matter in your actual build in PIO.
#
# NOTE: For now we plan on using a branch for the arduino-esp32 repo `feature/fws-custom-55d608e3-2.0.5` that is based off of the original `2.0.5` tag 
# where `55d608e3` was the commit SHA at that time.
#
# See CONFIGNOTES.md for more about what changes we've made to sdkconfig.

if ! [ -x "$(command -v python3)" ]; then
    echo "ERROR: python is not installed! Please install python first."
    exit 1
fi

if ! [ -x "$(command -v git)" ]; then
    echo "ERROR: git is not installed! Please install git first."
    exit 1
fi

TARGET="all"
BUILD_TYPE="all"
SKIP_ENV=0
SKIP_CAMERA=0
SKIP_RAINMAKER_AND_INSIGHTS=0
COPY_OUT=0
if [ -z $DEPLOY_OUT ]; then
    DEPLOY_OUT=0
fi

function print_help() {
    echo "Usage: build.sh [-s <optional>] [-A <arduino_branch>] [-a <arduino_commit>] [-I <idf_branch>] [-i <idf_commit>] [-x <optional>] [-y <optional>] [-j <esp32-camera commit>] [-k <esp-dl commit>] [-l <esp-rainmaker commit>] [-m <esp-dsp commit>] [-n <esp-littlefs commit>] [-o <tinyusb commit>] [-d <optional>] [-c <path>] [-t <target>] [-b <build|menuconfig|idf_libs|copy_bootloader|mem_variant>] [config ...]"
    echo "       -s     Skip installing/updating of ESP-IDF and all components"
    echo "       -A     Set which branch of arduino-esp32 to be used for compilation (required if not using -s)"
    echo "       -a     Set which commit of arduino-esp32 to be used for compilation (optional)"
    echo "       -I     Set which branch of ESP-IDF to be used for compilation"
    echo "       -i     Set which commit of ESP-IDF to be used for compilation"

    # Added the following so that we don't always have to hardcode the commit SHAs for these dependencies. 20250608
    # WARNING: If these commits aren't set as parameters, the hardcoded defaults in 
    # update-components.sh will be used.
    echo "       -x     Skip including esp-rainmaker (and insights) (may be necessary if using IDF v4.4.x as rainmaker has dependencies on v5)"
    echo "       -y     Skip including esp-camera"
    echo "       -j     Set which commit of esp32-camera to be used for compilation (ignored if -y is used)"
    echo "       -k     Set which commit of esp-dl to be used for compilation"
    echo "       -l     Set which commit of esp-rainmaker to be used for compilation"
    echo "       -m     Set which commit of esp-dsp commit to be used for compilation"
    echo "       -n     Set which commit of esp-littlefs commit to be used for compilation"
    echo "       -o     Set which commit of tinyusb commit to be used for compilation"

    echo "       -d     Deploy the build to github arduino-esp32"
    echo "       -c     Set the arduino-esp32 folder to copy the result to. ex. '$HOME/Arduino/hardware/espressif/esp32'"
    echo "       -t     Set the build target(chip). ex. 'esp32s3'"
    echo "       -b     Set the build type <build|menuconfig|idf_libs|copy_bootloader|mem_variant> to build the project and prepare for uploading to a board"
    echo "       ...    Specify additional configs to be applied. ex. 'qio 80m' to compile for QIO Flash@80MHz. Requires -b"
    exit 1
}

while getopts ":A:a:I:i:j:k:l:m:n:o:c:t:b:sxyd" opt; do
    case ${opt} in
        s )
            SKIP_ENV=1
            ;;
        x )
            SKIP_RAINMAKER_AND_INSIGHTS=1
            ;;
        y )
            SKIP_CAMERA=1
            ;;
        d )
            DEPLOY_OUT=1
            ;;
        c )
            export ESP32_ARDUINO="$OPTARG"
            COPY_OUT=1
            ;;
        A )
            export AR_BRANCH="$OPTARG"
            ;;
        a )
            export AR_COMMIT="$OPTARG"
            ;;
        I )
            export IDF_BRANCH="$OPTARG"
            ;;
        i )
            export IDF_COMMIT="$OPTARG"
            ;;

        j )
            export CAMERA_COMMIT="$OPTARG"
            ;;
        k )
            export DL_COMMIT="$OPTARG"
            ;;
        l )
            export RAINMAKER_COMMIT="$OPTARG"
            ;;
        m )
            export DSP_COMMIT="$OPTARG"
            ;;
        n )
            export LITTLEFS_COMMIT="$OPTARG"
            ;;
        o )
            export TINYUSB_COMMIT="$OPTARG"
            ;;

        t )
            TARGET=$OPTARG
            ;;
        b )
            b=$OPTARG
            if [ "$b" != "build" ] && 
               [ "$b" != "menuconfig" ] && 
               [ "$b" != "idf_libs" ] && 
               [ "$b" != "copy_bootloader" ] && 
               [ "$b" != "mem_variant" ]; then
                print_help
            fi
            BUILD_TYPE="$b"
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            print_help
            ;;
        : )
            echo "Invalid option: -$OPTARG requires an argument" 1>&2
            print_help
            ;;
    esac
done
shift $((OPTIND -1))
CONFIGS=$@

if [ $SKIP_ENV -eq 0 ]; then
    echo "* Installing/Updating ESP-IDF and all components..."

    echo "SKIP_RAINMAKER_AND_INSIGHTS [${SKIP_RAINMAKER_AND_INSIGHTS}]"
    echo "SKIP_CAMERA [${SKIP_CAMERA}]"

    # This is needed by update-components.sh
    export SKIP_RAINMAKER_AND_INSIGHTS
    export SKIP_CAMERA

    # update components from git
    echo "> components"
    ./tools/update-components.sh
    if [ $? -ne 0 ]; then exit 1; fi

    # install esp-idf
    echo "> esp-idf"
    source ./tools/install-esp-idf.sh
    if [ $? -ne 0 ]; then exit 1; fi
else
    echo "WARNING: Skipping installation and updating of ESP-IDF and all components"
    source ./tools/config.sh

    # This is necessary or else idf.py comment further below will fail. 20250611
    source $IDF_PATH/export.sh
fi

if [ "$BUILD_TYPE" != "all" ]; then
    if [ "$TARGET" = "all" ]; then
        echo "ERROR: You need to specify target for non-default builds"
        print_help
    fi
    configs="configs/defconfig.common;configs/defconfig.$TARGET"
    
    # Target Features Configs
    for target_json in `jq -c '.targets[]' configs/builds.json`; do
        target=$(echo "$target_json" | jq -c '.target' | tr -d '"')
        if [ "$TARGET" == "$target" ]; then
            for defconf in `echo "$target_json" | jq -c '.features[]' | tr -d '"'`; do
                configs="$configs;configs/defconfig.$defconf"
            done
        fi
    done

    # Configs From Arguments
    for conf in $CONFIGS; do
        configs="$configs;configs/defconfig.$conf"
    done

    echo "idf.py -DIDF_TARGET=\"$TARGET\" -DSDKCONFIG_DEFAULTS=\"$configs\" $BUILD_TYPE"
    rm -rf build sdkconfig
    idf.py -DIDF_TARGET="$TARGET" -DSDKCONFIG_DEFAULTS="$configs" $BUILD_TYPE
    if [ $? -ne 0 ]; then exit 1; fi
    exit 0
fi

echo "Removing build, sdkconfig and out..."
rm -rf build sdkconfig out

# Add components version info
mkdir -p "$AR_TOOLS/sdk" && rm -rf version.txt && rm -rf "$AR_TOOLS/sdk/versions.txt"
component_version="esp-idf: "$(git -C "$IDF_PATH" symbolic-ref --short HEAD || git -C "$IDF_PATH" tag --points-at HEAD)" "$(git -C "$IDF_PATH" rev-parse --short HEAD)
echo $component_version >> version.txt && echo $component_version >> "$AR_TOOLS/sdk/versions.txt"
for component in `ls "$AR_COMPS"`; do
    if [ -d "$AR_COMPS/$component/.git" ] || [ -d "$AR_COMPS/$component/.github" ]; then
        component_version="$component: "$(git -C "$AR_COMPS/$component" symbolic-ref --short HEAD || git -C "$AR_COMPS/$component" tag --points-at HEAD)" "$(git -C "$AR_COMPS/$component" rev-parse --short HEAD)
        echo $component_version >> version.txt && echo $component_version >> "$AR_TOOLS/sdk/versions.txt"
    fi
done
component_version="tinyusb: "$(git -C "$AR_COMPS/arduino_tinyusb/tinyusb" symbolic-ref --short HEAD || git -C "$AR_COMPS/arduino_tinyusb/tinyusb" tag --points-at HEAD)" "$(git -C "$AR_COMPS/arduino_tinyusb/tinyusb" rev-parse --short HEAD)
echo $component_version >> version.txt && echo $component_version >> "$AR_TOOLS/sdk/versions.txt"

#targets_count=`jq -c '.targets[] | length' configs/builds.json`
for target_json in `jq -c '.targets[]' configs/builds.json`; do
    target=$(echo "$target_json" | jq -c '.target' | tr -d '"')

    if [ "$TARGET" != "all" ] && [ "$TARGET" != "$target" ]; then
        echo "* Skipping Target: $target"
        continue
    fi

    echo "* Target: $target"

    # Build Main Configs List
    main_configs="configs/defconfig.common;configs/defconfig.$target"
    for defconf in `echo "$target_json" | jq -c '.features[]' | tr -d '"'`; do
        main_configs="$main_configs;configs/defconfig.$defconf"
    done

    # Build IDF Libs
    idf_libs_configs="$main_configs"
    for defconf in `echo "$target_json" | jq -c '.idf_libs[]' | tr -d '"'`; do
        idf_libs_configs="$idf_libs_configs;configs/defconfig.$defconf"
    done
    echo "* Build IDF-Libs: $idf_libs_configs"
    rm -rf build sdkconfig
    idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$idf_libs_configs" idf_libs
    if [ $? -ne 0 ]; then exit 1; fi

    # Build Bootloaders
    for boot_conf in `echo "$target_json" | jq -c '.bootloaders[]'`; do
        bootloader_configs="$main_configs"
        for defconf in `echo "$boot_conf" | jq -c '.[]' | tr -d '"'`; do
            bootloader_configs="$bootloader_configs;configs/defconfig.$defconf";
        done
        echo "* Build BootLoader: $bootloader_configs"
        rm -rf build sdkconfig
        idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$bootloader_configs" copy_bootloader
        if [ $? -ne 0 ]; then exit 1; fi
    done

    # Build Memory Variants
    for mem_conf in `echo "$target_json" | jq -c '.mem_variants[]'`; do
        mem_configs="$main_configs"
        for defconf in `echo "$mem_conf" | jq -c '.[]' | tr -d '"'`; do
            mem_configs="$mem_configs;configs/defconfig.$defconf";
        done
        echo "* Build Memory Variant: $mem_configs"
        rm -rf build sdkconfig
        idf.py -DIDF_TARGET="$target" -DSDKCONFIG_DEFAULTS="$mem_configs" mem_variant
        if [ $? -ne 0 ]; then exit 1; fi
    done
done

# update package_esp32_index.template.json
if [ "$BUILD_TYPE" = "all" ]; then
    python3 ./tools/gen_tools_json.py -i "$IDF_PATH" -j "$AR_COMPS/arduino/package/package_esp32_index.template.json" -o "$AR_OUT/"
    if [ $? -ne 0 ]; then exit 1; fi
fi

# archive the build
if [ "$BUILD_TYPE" = "all" ]; then
    ./tools/archive-build.sh
    if [ $? -ne 0 ]; then exit 1; fi
fi

# copy everything to arduino-esp32 installation
if [ $COPY_OUT -eq 1 ] && [ -d "${ESP32_ARDUINO}" ]; then
    ./tools/copy-to-arduino.sh
fi

if [ $DEPLOY_OUT -eq 1 ]; then
    ./tools/push-to-arduino.sh
fi
