#/bin/bash
# 20250608: Added default commits and ability to skip rainmaker. Also added support for checking out a specific commit for arduino-esp32.

echo "SKIP_RAINMAKER_AND_INSIGHTS [${SKIP_RAINMAKER_AND_INSIGHTS}]"
echo "SKIP_CAMERA [${SKIP_CAMERA}]"

source ./tools/config.sh

# NOTE: None of these were forked for lemonkey 20250607
# WARNING: The latest versions of these repos may be dependent on a newer version of esp-idf, 
# but the branch we're using for the lib builder repo is v4.4, unless there's an existing
# bug...
#
# When we try to build the esp-idf library we get this error: ERROR: Because project depends on both idf (4.4.*) and idf (>=5.0), version  solving failed.
# But this doesn't happen if we use idf.py to build a hello world sketch...
#
# The versions of these repos that are tied to the version of esp-idf we're using for FWS are (see versions.txt):
# 	esp32-camera: master 5611989
# 	esp-dl: master f3006d7
# 	esp-rainmaker: master 3736c12
#   insights??? ESP Insights: A remote diagnostics/observability framework for connected devices https://github.com/espressif/esp-insights
# 	esp-dsp: master 401faf8
# 	esp_littlefs: master 485a037
# 	esp-sr: master b578f17 ??? (speech recognition)
# 	tinyusb: master 111515a29

# NOTE: These hardcoded SHAs will be used if commit switches aren't set for the following libraries.
# Comment out the default commits if you want to use the latest versions off master.
# And if you created a fork, replace the repo URLs below.

# WARNING: If `SKIP_CAMERA` is set to 1 (via -y switch), esp-camera won't be built.
CAMERA_REPO_URL="https://github.com/espressif/esp32-camera.git"
# `-j` build.sh parameter
CAMERA_DEFAULT_COMMIT="5611989"

DL_REPO_URL="https://github.com/espressif/esp-dl.git"
# `-k` build.sh parameter
DL_DEFAULT_COMMIT="f3006d7"

# WARNING: esp-rainmaker and esp-insights require esp-idf 5.0 and we don't need it
# ESP RainMaker is an end-to-end solution offered by Espressif to enable remote control and monitoring for ESP32-S2 and ESP32 based products without any configuration required in the Cloud. The primary components of this solution are:
# Removing these two repos from the build process (update-components.sh)
# Change this if we ever want it and we also upgrade to esp-idf 5+
# When `-x` parameter is set for build.sh, both of these will be skipped during the build.
# See `SKIP_RAINMAKER_AND_INSIGHTS`.
# ----------
RMAKER_REPO_URL="https://github.com/espressif/esp-rainmaker.git"
# `-l` build.sh parameter
RMAKER_DEFAULT_COMMIT="3736c12"

INSIGHTS_REPO_URL="https://github.com/espressif/esp-insights.git"
# NOTE: there is no way to specify a specific commit here. I think this is 
# a submodule of esp-rainmaker.
# ----------

DSP_REPO_URL="https://github.com/espressif/esp-dsp.git"
# `-m` build.sh parameter
DSP_DEFAULT_COMMIT="401faf8"

LITTLEFS_REPO_URL="https://github.com/joltwallet/esp_littlefs.git"
# `-n build.sh parameter
LITTLEFS_DEFAULT_COMMIT="485a037"

TINYUSB_REPO_URL="https://github.com/hathach/tinyusb.git"
# `-o` build.sh parameter
TINYUSB_DEFAULT_COMMIT="111515a29"

#
# CLONE/UPDATE ARDUINO
#
# NOTE: Branch used controlled by `-A` build.sh parameter.`
echo "Updating ESP32 Arduino..."
if [ ! -d "$AR_COMPS/arduino" ]; then
	git clone $AR_REPO_URL "$AR_COMPS/arduino"
fi

if [ -z $AR_BRANCH ]; then
	if [ -z $GITHUB_HEAD_REF ]; then
		current_branch=`git branch --show-current`
	else
		current_branch="$GITHUB_HEAD_REF"
	fi
	echo "Current Branch: $current_branch"
	if [[ "$current_branch" != "master" && `git_branch_exists "$AR_COMPS/arduino" "$current_branch"` == "1" ]]; then
		export AR_BRANCH="$current_branch"
	else
		if [ -z "$IDF_COMMIT" ]; then #commit was not specified at build time
			AR_BRANCH_NAME="idf-$IDF_BRANCH"
		else
			AR_BRANCH_NAME="idf-$IDF_COMMIT"
		fi
		has_ar_branch=`git_branch_exists "$AR_COMPS/arduino" "$AR_BRANCH_NAME"`
		if [ "$has_ar_branch" == "1" ]; then
			export AR_BRANCH="$AR_BRANCH_NAME"
		else
			has_ar_branch=`git_branch_exists "$AR_COMPS/arduino" "$AR_PR_TARGET_BRANCH"`
			if [ "$has_ar_branch" == "1" ]; then
				export AR_BRANCH="$AR_PR_TARGET_BRANCH"
			fi
		fi
	fi
else
	echo "Specific branch was passed to build.sh [${AR_BRANCH}]"
fi

if [ "$AR_BRANCH" ]; then
	echo "Checking out branch [${AR_BRANCH}] for [${AR_REPO_URL}] and pulling LATEST commits..."
	git -C "$AR_COMPS/arduino" checkout "$AR_BRANCH" && \
	git -C "$AR_COMPS/arduino" fetch && \
	git -C "$AR_COMPS/arduino" pull --ff-only
	if [ "$AR_COMMIT" ]; then
		echo "Checking out specific commit [${AR_COMMIT}] for [${AR_REPO_URL}]..."
		git -C "$AR_COMPS/arduino" checkout "$AR_COMMIT"
	fi
else
	echo "ERROR: Branch for Arduino required!"
	exit 1
fi
if [ $? -ne 0 ]; then exit 1; fi

#
# CLONE/UPDATE ESP32-CAMERA
#
if [ $SKIP_CAMERA -ne 1 ]; then
	echo "Updating ESP32 Camera..."
	if [ ! -d "$AR_COMPS/esp32-camera" ]; then
		echo "Cloning esp32-camera for the first time!"
		git clone $CAMERA_REPO_URL "$AR_COMPS/esp32-camera"
	else
		echo "esp32-camera repo has already been cloned."
	fi
	echo "Fetching..."
	git -C "$AR_COMPS/esp32-camera" fetch
	if [ ! -z "${CAMERA_COMMIT}" ]; then 
		echo "Using given commit [${CAMERA_COMMIT}]"
		git -C "$AR_COMPS/esp32-camera" checkout "${CAMERA_COMMIT}"
	else
		if [ ! -z "${CAMERA_DEFAULT_COMMIT}" ]; then 
			echo "Using hardcoded commit [${CAMERA_DEFAULT_COMMIT}]"
			git -C "$AR_COMPS/esp32-camera" checkout "${CAMERA_DEFAULT_COMMIT}"
		else 
			echo "Pulling latest from repo (no commit specified)..."
			git -C "$AR_COMPS/esp32-camera" pull --ff-only
		fi
	fi
	if [ $? -ne 0 ]; then exit 1; fi
else
	echo "Skipping esp-camera!"
fi

#
# CLONE/UPDATE ESP-DL
#
echo "Updating ESP-DL..."
if [ ! -d "$AR_COMPS/esp-dl" ]; then
	echo "Cloning esp32-dl for the first time!"
	git clone $DL_REPO_URL "$AR_COMPS/esp-dl"
else
	echo "esp-dl repo has already been cloned."
fi
echo "Fetching..."
git -C "$AR_COMPS/esp-dl" fetch
if [ ! -z "${DL_COMMIT}" ]; then 
	echo "Using given commit [${DL_COMMIT}]"
	git -C "$AR_COMPS/esp-dl" reset --hard "${DL_COMMIT}"
else
	if [ ! -z "${DL_DEFAULT_COMMIT}" ]; then 
		echo "Using hardcoded commit [${DL_DEFAULT_COMMIT}]"
		git -C "$AR_COMPS/esp-dl" reset --hard "${DL_DEFAULT_COMMIT}"
	else
		echo "Using original hardcoded commit '0632d2447dd49067faabe9761d88fa292589d5d9'"
		# NOTE: This must be tied to IDF 4.4.x (original version of this script hardcodes this SHA on the v4.4 branch of the lib builder repo)
		git -C "$AR_COMPS/esp-dl" reset --hard 0632d2447dd49067faabe9761d88fa292589d5d9
	fi
fi
if [ $? -ne 0 ]; then exit 1; fi

#
# CLONE/UPDATE ESP-LITTLEFS
#
echo "Updating ESP-LITTLEFS..."
if [ ! -d "$AR_COMPS/esp_littlefs" ]; then
	echo "Cloning esp32-camera for the first time!"
	git clone $LITTLEFS_REPO_URL "$AR_COMPS/esp_littlefs"
fi
echo "Fetching..."
git -C "$AR_COMPS/esp_littlefs" fetch
if [ ! -z "${LITTLEFS_COMMIT}" ]; then 
	echo "Using given commit [${LITTLEFS_COMMIT}]"
	git -C "$AR_COMPS/esp_littlefs" checkout "${LITTLEFS_COMMIT}" 
else
	if [ ! -z "${LITTLEFS_DEFAULT_COMMIT}" ]; then 
		echo "Using hardcoded commit [${LITTLEFS_DEFAULT_COMMIT}]"
		git -C "$AR_COMPS/esp_littlefs" checkout "${LITTLEFS_DEFAULT_COMMIT}" 
	else
		echo "Pulling latest from repo (no commit specified)..."
		git -C "$AR_COMPS/esp_littlefs" pull --ff-only
	fi
fi
echo "Updating esp_littlefs submodule..."
git -C "$AR_COMPS/esp_littlefs" submodule update --init --recursive
if [ $? -ne 0 ]; then exit 1; fi

#
# CLONE/UPDATE ESP-RAINMAKER (unless SKIP_RAINMAKER_AND_INSIGHTS=1)
#
# WARNING: If using IDF 4.4.x, the build will fail due to dependencies in RAINMAKER requiring v5+
# We don't really need this library so it's safe to skip until we upgrade to IDF v5+
#
if [ $SKIP_RAINMAKER_AND_INSIGHTS -ne 1 ]; then
	echo "Updating ESP-RainMaker (and insights)..."
	if [ ! -d "$AR_COMPS/esp-rainmaker" ]; then
		echo "Cloning esp32-rainmaker for the first time!"
		git clone $RMAKER_REPO_URL "$AR_COMPS/esp-rainmaker"
	fi
	echo "Fetching..."
	git -C "$AR_COMPS/esp-rainmaker" fetch
	if [ ! -z "${RAINMAKER_COMMIT}" ]; then 
		echo "Using given commit [${RAINMAKER_COMMIT}]"
		git -C "$AR_COMPS/esp-rainmaker" checkout "${RAINMAKER_COMMIT}" 
	else
		if [ ! -z "${RAINMAKER_DEFAULT_COMMIT}" ]; then 
			echo "Using hardcoded commit [${RAINMAKER_DEFAULT_COMMIT}]"
			git -C "$AR_COMPS/esp-rainmaker" checkout "${RAINMAKER_DEFAULT_COMMIT}" 
		else
			echo "Using original hardcoded commit 'd8e93454f495bd8a414829ec5e86842b373ff555'"
			git -C "$AR_COMPS/esp-rainmaker" reset --hard d8e93454f495bd8a414829ec5e86842b373ff555
		fi
	fi
	echo "Updating esp-rainmaker submodule..."
	git -C "$AR_COMPS/esp-rainmaker" submodule update --init --recursive
	if [ $? -ne 0 ]; then exit 1; fi
else
	echo "Skipping esp-rainmaker and insights!"
fi

#
# CLONE/UPDATE ESP-DSP
#
echo "Updating ESP-DSP..."
if [ ! -d "$AR_COMPS/espressif__esp-dsp" ]; then
	echo "Cloning espressif__esp-dsp for the first time!"
	git clone $DSP_REPO_URL "$AR_COMPS/espressif__esp-dsp"
fi
echo "Fetching..."
git -C "$AR_COMPS/espressif__esp-dsp" fetch
if [ ! -z "${DSP_COMMIT}" ]; then 
	echo "Using given commit [${DSP_COMMIT}]"
	git -C "$AR_COMPS/espressif__esp-dsp" checkout "${DSP_COMMIT}"
else
	if [ ! -z "${DSP_DEFAULT_COMMIT}" ]; then 
		echo "Using hardcoded commit [${DSP_DEFAULT_COMMIT}]"
		git -C "$AR_COMPS/espressif__esp-dsp" checkout "${DSP_DEFAULT_COMMIT}"
	else 
		echo "Pulling latest from repo (no commit specified)..."
		git -C "$AR_COMPS/espressif__esp-dsp" pull --ff-only
	fi
fi
if [ $? -ne 0 ]; then exit 1; fi

#
# CLONE/UPDATE TINYUSB
#
echo "Updating TinyUSB..."
if [ ! -d "$AR_COMPS/arduino_tinyusb/tinyusb" ]; then
	echo "Cloning arduino_tinyusb/tinyusb for the first time!"
	git clone $TINYUSB_REPO_URL "$AR_COMPS/arduino_tinyusb/tinyusb"
fi
git -C "$AR_COMPS/arduino_tinyusb/tinyusb" fetch
if [ ! -z "${TINYUSB_COMMIT}" ]; then 
	echo "Using given commit [${TINYUSB_COMMIT}]"
	git -C "$AR_COMPS/arduino_tinyusb/tinyusb" checkout "${TINYUSB_COMMIT}"
else
	if [ ! -z "${TINYUSB_DEFAULT_COMMIT}" ]; then 
		echo "Using hardcoded commit [${TINYUSB_DEFAULT_COMMIT}]"
		git -C "$AR_COMPS/arduino_tinyusb/tinyusb" checkout "${TINYUSB_DEFAULT_COMMIT}"
	else 
		echo "Pulling latest from repo (no commit specified)..."
		git -C "$AR_COMPS/arduino_tinyusb/tinyusb" pull --ff-only
	fi
fi
if [ $? -ne 0 ]; then exit 1; fi