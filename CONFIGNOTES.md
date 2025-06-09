# Sun 20250608

* 4:34PM Was able to invoke the menuconfig GUI with the following:

  `./build.sh -I feature/fws-custom-1b16ef6cfc-4.4.2 -i 1b16ef6 -A feature/fws-custom-55d608e3-2.0.5 -x -j 5611989 -k f3006d7 -m 401faf8 -n 485a037 -o 111515a29 -c /Users/lemonkey/Source/_3rd/esp32-arduino-lib-builder/custom-arduino-esp32-build -t esp32 -b menuconfig`

  - Top level menu items:

    * SDK tool configuration
    * Build type
    * Application manager
    * Bootloader config
    * Security features
    * Serial flasher config
    * Partition table
    * ESP RainMaker Config
    * Arduino Configuration
    * Arduino TinyUSB 
    * Compiler options
    * Component config
    * Compatibility options

NOTE: According to https://mm.kno.wled.ge/advanced/compile-arduino-esp32/, "Generally, you only will want to modify things in "Arduino Configuration" and the menus below it (Arduino TinyUSB, Compiler options, etc) 
  - When using [S] Save, "this will create an sdkconfig file in the root of esp32-arduino-lib-builder" to be used with subsequent builds of the arduino-esp32 library.
  - The sdkconfig file is annotated to show what categories each config belongs to

https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/kconfig.html
  - WARNING: Subsequent sections contain the list of available ESP-IDF options automatically generated from Kconfig files. Note that due to dependencies between options, some options listed here may not be visible by default in menuconfig.
  - WARNING: This is for the stable release (v5.4.1 at the current time).
    - Cannot view version of the doc for v4.4 of ESP-IDF that we're still currently using.

* 4:19PM Noteworthy config options:

  - CONFIG_BOOTLOADER_PROJECT_VER: Project version. It is placed in "version" field of the esp_bootloader_desc structure. The type of this field is "uint32_t".

    * Default: 1

  - CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION: This option sets compiler optimization level (gcc -O argument) for the bootloader.

    * Available options:

      Size (-Os with GCC, -Oz with Clang) (CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_SIZE)
      Debug (-Og) (CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_DEBUG)
      Optimize for performance (-O2) (CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_PERF)
      Debug without optimization (-O0) (Deprecated, will be removed in IDF v6.0) (CONFIG_BOOTLOADER_COMPILER_OPTIMIZATION_NONE)

  - CONFIG_BOOTLOADER_LOG_LEVEL: Specify how much output to see in bootloader logs.

    * Available options:

      No output (CONFIG_BOOTLOADER_LOG_LEVEL_NONE)
      Error (CONFIG_BOOTLOADER_LOG_LEVEL_ERROR)
      Warning (CONFIG_BOOTLOADER_LOG_LEVEL_WARN)
      Info (CONFIG_BOOTLOADER_LOG_LEVEL_INFO)
      Debug (CONFIG_BOOTLOADER_LOG_LEVEL_DEBUG)
      Verbose (CONFIG_BOOTLOADER_LOG_LEVEL_VERBOSE)

  - CONFIG_BOOTLOADER_LOG_COLORS: Use ANSI terminal colors in log output Enable ANSI terminal color codes. In order to view these, your terminal program must support ANSI color codes.

    * Default: No (disabled)

  - CONFIG_BOOTLOADER_FACTORY_RESET: Allows to reset the device to factory settings: - clear one or more data partitions; - boot from "factory" partition. The factory reset will occur if there is a GPIO input held at the configured level while device starts up. See settings below.

    * Default: No (disabled)

  - CONFIG_BOOTLOADER_NUM_PIN_FACTORY_RESET: see above
  - CONFIG_BOOTLOADER_FACTORY_RESET_PIN_LEVEL: see above
  - CONFIG_BOOTLOADER_OTA_DATA_ERASE: see above
  - CONFIG_BOOTLOADER_DATA_FACTORY_RESET: see above

  - CONFIG_BOOTLOADER_REGION_PROTECTION_ENABLE: Protects the unmapped memory regions of the entire address space from unintended accesses. This will ensure that an exception will be triggered whenever the CPU performs a memory operation on unmapped regions of the address space. NOTE: Disabling this config on some targets (ESP32-C6, ESP32-H2, ESP32-C5) would not generate an exception when reading from or writing to 0x0.

    * Default: Yes (enabled)

  - CONFIG_BOOTLOADER_WDT_ENABLE: Use RTC watchdog in start code

    * Default: Yes (enabled)

  - >>> CONFIG_BOOTLOADER_WDT_TIME_MS: Timeout for RTC watchdog (ms)

    - Verify that this parameter is correct and more then the execution time. Pay attention to options such as reset to factory, trigger test partition and encryption on boot - these options can increase the execution time. Note: RTC_WDT will reset while encryption operations will be performed.

    * Range: from 0 to 120000 (0 to 12 seconds)

    * Default: 9000 <<<<<<< 9000 milliseconds or 9 seconds is the default watchdog timer threshold

      - WARNING: Different from "Interrupt watchdog" config? Currently set to 300ms

        - see also "Task Watchdog timeout period (seconds)" currently set to 5 seconds

  - CONFIG_APP_COMPILE_TIME_DATE: Use time/date stamp for app. 

    - If not set, time/date stamp will be excluded from app image. This can be useful for getting the same binary image files made from the same source, but at different times.

    * It's currently enabled (default?)

  - CONFIG_ESPTOOLPY_FLASHFREQ: Flash SPI speed

    - NOTE: Flash size is detected automatically when flashing bootloader

    * 40MHz currently set (can be 80, 40, 26, 20)

  - CONFIG_ESPTOOLPY_BEFORE: Configure whether esptool.py should reset the ESP32 before flashing.

    - Automatic resetting depends on the RTS & DTR signals being wired from the serial port to the ESP32. Most USB development boards do this internally.

    - Available options:

      Reset to bootloader (CONFIG_ESPTOOLPY_BEFORE_RESET) <<<<< currently set 
      No reset (CONFIG_ESPTOOLPY_BEFORE_NORESET)

  - CONFIG_ESPTOOLPY_AFTER: Configure whether esptool.py should reset the ESP32 after flashing.

    - Automatic resetting depends on the RTS & DTR signals being wired from the serial port to the ESP32. Most USB development boards do this internally.

    - Available options:

      Reset after flashing (CONFIG_ESPTOOLPY_AFTER_RESET) <<<<< currently set 
      Stay in bootloader (CONFIG_ESPTOOLPY_AFTER_NORESET)

  - CONFIG_COMPILER_OPTIMIZATION: This option sets compiler optimization level (gcc -O argument) for the app.

    - We control this via platformio.ini by injecting compiler flags..

  - >>> CONFIG_COMPILER_CXX_EXCEPTIONS: Enabling this option compiles all IDF C++ files with exception support enabled.

    - Enabling this option currently adds an additional ~500 bytes of heap overhead when an exception is thrown in user code for the first time.

    * Default value: No (disabled)

    - NOTE: But this doesn't meant that you can use exceptions in the Arduino C++ code we write as we've found out.

    - WARNING: it's currently enabled with most recently generated sdkconfig from the last lib build.

  - CONFIG_COMPILER_CXX_RTTI: Enabling this option compiles all C++ files with RTTI support enabled. This increases binary size (typically by tens of kB) but allows using dynamic_cast conversion and typeid operator.

    * Default value: No (disabled)

  - >>> CONFIG_COMPILER_DUMP_RTL_FILES: If enabled, RTL files will be produced during compilation. These files can be used by other tools, for example to calculate call graphs.

    * Default value: No (disabled)

    - Would this only be for the ESP-IDF / arduino-esp32 code and not our project code???

    - TODO: Can call graphs be generated for our project code? 6/8

 NOTE: There are a LOT of configs under "Component config". One of the original goals was to disable BLUETOOTH to gain more free heap space.

  - >>> CONFIG_I2C_ENABLE_DEBUG_LOG: whether to enable the debug log message for I2C driver. Note that this option only controls the I2C driver log, will not affect other drivers.

    * Default value: No (disabled)

  - >>> CRITICAL >>> CONFIG_ESP_EVENT_LOOP_PROFILING: Enable event loop profiling

    - Enables collections of statistics in the event loop library such as the number of events posted to/recieved by an event loop, number of callbacks involved, number of events dropped to to a full event loop queue, run time of event handlers, and number of times/run time of each event handler.

    * Default value: No (disabled)

  - >>> CRITICAL >>> CONFIG_ESP_GDBSTUB_SUPPORT_TASKS: Enable listing FreeRTOS tasks through GDB Stub

    - If enabled, GDBStub can supply the list of FreeRTOS tasks to GDB. Thread list can be queried from GDB using 'info threads' command. Note that if GDB task lists were corrupted, this feature may not work. If GDBStub fails, try disabling this feature.

    * Default value: Yes (enabled)

  - CONFIG_ESP_GDBSTUB_MAX_TASKS: Maximum number of tasks supported by GDB Stub

    * Default value: 32

  - CONFIG_ESP_HTTP_CLIENT_ENABLE_HTTPS: This option will enable https protocol by linking esp-tls library and initializing SSL transport

    * Default value: Yes (enabled)

  - CONFIG_ESP_HTTP_CLIENT_ENABLE_BASIC_AUTH: This option will enable HTTP Basic Authentication. It is disabled by default as Basic auth uses unencrypted encoding, so it introduces a vulnerability when not using TLS

    * Default value: No (disabled)

  - Various HTTP and HTTPS server configs (we're not using build-in http server; see async webserver library; but does it use the built in http server under the hood?)

    - CONFIG_HTTPD_MAX_REQ_HDR_LEN (512 by default)
    - CONFIG_HTTPD_MAX_URI_LEN (512 by default)
    - CONFIG_HTTPD_ERR_RESP_NO_DELAY (Yes by default)
    - CONFIG_ESP_HTTPS_SERVER_ENABLE (WARNING: currently enabled but we're not using it)

  - NOTE: Various sleep configs (we're not using these yet)

  - >>> CONFIG_RTC_CLK_SRC: Choose which clock is used as RTC clock source.

    - Options:

      Internal 150 kHz RC oscillator (CONFIG_RTC_CLK_SRC_INT_RC)
      External 32kHz crystal (CONFIG_RTC_CLK_SRC_EXT_CRYS)
      External 32kHz oscillator at 32K_XN pin (CONFIG_RTC_CLK_SRC_EXT_OSC)
      Internal 8.5MHz oscillator, divided by 256 (~33kHz) (CONFIG_RTC_CLK_SRC_INT_8MD256)    
        - More accurate than Internal 150, uses more amps during sleep.

    - WARNING: We can't edit any of the configs under "RTC Clock Config" via menuconfig.

  - CONFIG_LCD_ENABLE_DEBUG_LOG: whether to enable the debug log message for LCD driver. Note that, this option only controls the LCD driver log, won't affect other drivers.

    * Default: No (disabled)

  - >>> CONFIG_PM_ENABLE: If enabled, application is compiled with support for power management. This option has run-time overhead (increased interrupt latency, longer time to enter idle state), and it also reduces accuracy of RTOS ticks and timers used for timekeeping. Enable this option if application uses power management APIs.

    * Default: No (if __DOXYGEN__) (currently not set)

    
  - >>> CRITICAL >>> CONFIG_ESP_DEFAULT_CPU_FREQ_MHZ: CPU frequency to be set on application startup.

    - Available options:

      40 MHz (CONFIG_ESP_DEFAULT_CPU_FREQ_MHZ_40)
      80 MHz (CONFIG_ESP_DEFAULT_CPU_FREQ_MHZ_80)
      160 MHz (CONFIG_ESP_DEFAULT_CPU_FREQ_MHZ_160)
      240 MHz (CONFIG_ESP_DEFAULT_CPU_FREQ_MHZ_240)

    - NOTE: Currently set to 160, but our board supports 240!

      CONFIG_ESP32_DEFAULT_CPU_FREQ_160=y
      CONFIG_ESP32_DEFAULT_CPU_FREQ_MHZ=160

    - TODO: Look into setting CPU frequency to 240.

  - >>> CONFIG_ESP_SYSTEM_EVENT_QUEUE_SIZE: System event queue size

    * Default value: 32 (set to 32 in sdkconfig)

  - >>> CONFIG_ESP_SYSTEM_EVENT_TASK_STACK_SIZE: Event loop task stack size

    * Default value: 2304 (set to 2048 in sdkconfig)

  - >>> CONFIG_ESP_MAIN_TASK_STACK_SIZE: Configure the "main task" stack size. This is the stack of the task which calls app_main(). If app_main() returns then this task is deleted and its stack memory is freed.

    * Default value: 3584 (set to 4096 in sdkconfig)

    - NOTE: We set this in main.cpp with an override using `SET_LOOP_TASK_STACK_SIZE`

  - CONFIG_ESP_MAIN_TASK_AFFINITY: Configure the "main task" core affinity. This is the used core of the task which calls app_main(). If app_main() returns then this task is deleted.

    * Currently set to 0x0 in sdkconfig (core 0)

  - CONFIG_ESP_MINIMAL_SHARED_STACK_SIZE: Minimal value of size, in bytes, accepted to execute a expression with shared stack.

    * Currently set to 2048 in sdkconfig (default)

  - CONFIG_ESP_CONSOLE_UART: Select where to send console output (through stdout and stderr).

    Available options:

      Default: UART0 (CONFIG_ESP_CONSOLE_UART_DEFAULT) (also set in sdkconfig)
      USB CDC (CONFIG_ESP_CONSOLE_USB_CDC)
      USB Serial/JTAG Controller (CONFIG_ESP_CONSOLE_USB_SERIAL_JTAG)
      Custom UART (CONFIG_ESP_CONSOLE_UART_CUSTOM)
      None (CONFIG_ESP_CONSOLE_NONE)

  - CONFIG_ESP_CONSOLE_SECONDARY: Channel for console secondary output

    Available options:

    No secondary console (CONFIG_ESP_CONSOLE_SECONDARY_NONE)
    USB_SERIAL_JTAG PORT (CONFIG_ESP_CONSOLE_SECONDARY_USB_SERIAL_JTAG)

    - NOTE: not set in sdkconfig

  - >>> CONFIG_ESP_INT_WDT: This watchdog timer can detect if the FreeRTOS tick interrupt has not been called for a certain time, either because a task turned off interrupts and did not turn them on for a long time, or because an interrupt handler did not return. It will try to invoke the panic handler first and failing that reset the SoC.

    * Default value: Yes (enabled)

  - >>> CONFIG_ESP_INT_WDT_TIMEOUT_MS: The timeout of the watchdog, in milliseconds. Make this higher than the FreeRTOS tick rate.

    * Range: 10 to 10000 (default 800 if CONFIG_SPIRAM) 

    - WARNING: Set to 300 in sdkconfig

  - >>> CONFIG_ESP_INT_WDT_CHECK_CPU1: Also detect if interrupts on CPU 1 are disabled for too long.

    - Currently set to y in sdkconfig

  - >>> CONFIG_ESP_TASK_WDT_EN: The Task Watchdog Timer can be used to make sure individual tasks are still running. Enabling this option will enable the Task Watchdog Timer. It can be either initialized automatically at startup or initialized after startup (see Task Watchdog Timer API Reference)

    - Default: yes (enabled) but not set in sdkconfig

    - WARNING: sdkconfig refers to this as CONFIG_ESP_TASK_WDT (something changed after v4.4?)

      - Can't even view v4.4 version of the documentation we're reviewing!

  - >>> CONFIG_ESP_DEBUG_OCDAWARE: The FreeRTOS panic and unhandled exception handers can detect a JTAG OCD debugger and instead of panicking, have the debugger stop on the offending instruction.

    - WARNING: Not available in v4.4?

  - >>> CONFIG_ESP_BROWNOUT_DET (CONFIG_BROWNOUT_DET in v4.4): The ESP has a built-in brownout detector which can detect if the voltage is lower than a specific value. If this happens, it will reset the chip in order to prevent unintended behaviour.

    * Default: yes (enabled)

  - >>> CONFIG_ESP_BROWNOUT_DET_LVL_SEL (CONFIG_BROWNOUT_DET_LVL in v4.4): The brownout detector will reset the chip when the supply voltage is approximately below this level. Note that there may be some variation of brownout voltage level between each ESP chip.

    Available options:

      2.43V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_0) <<<< default also set in sdkconfig
      2.48V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_1)
      2.58V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_2)
      2.62V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_3)
      2.67V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_4)
      2.70V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_5)
      2.77V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_6)
      2.80V +/- 0.05 (CONFIG_ESP_BROWNOUT_DET_LVL_SEL_7)

  - CONFIG_ESP_IPC_TASK_STACK_SIZE (CONFIG_IPC_TASK_STACK_SIZE in v4.4): Configure the IPC tasks stack size. An IPC task runs on each core (in dual core mode), and allows for cross-core function calls. See IPC documentation for more details. The default IPC stack size should be enough for most common simple use cases. However, users can increase/decrease the stack size to their needs.

    * Range: 512 to 65536 (default 1024, as set in sdkconfig)

  - CONFIG_ESP_TIMER_PROFILING: If enabled, esp_timer_dump will dump information such as number of times the timer was started, number of times the timer has triggered, and the total time it took for the callback to run. This option has some effect on timer performance and the amount of memory used for timer storage, and should only be used for debugging/testing purposes.

    - Note that this is not the same as FreeRTOS timer task. To configure FreeRTOS timer task size, see "FreeRTOS timer task stack size" option in "FreeRTOS".

    * Default value: no (disabled)

NOTE: Tons of WIFI configs

  - CONFIG_ESP_HOST_WIFI_ENABLED (or CONFIG_ESP32_WIFI_ENABLED in our sdkconfig): Host WiFi Enable

    * Default value: No (but yes in sdkconfig)

    - See other settings...

    - WARNING: might be related to our socket disconnections when http request in progress and websocket is in progress...

      - see also CONFIG_ESP_WIFI_TX_BUFFER

  - CONFIG_ESP_COREDUMP_TO_FLASH_OR_UART (or CONFIG_ESP_COREDUMP_ENABLE_TO_FLASH v4.4): Select place to store core dump: flash, uart or none (to disable core dumps generation).

    - Core dumps to Flash are not available if PSRAM is used for task stacks.

    - If core dump is configured to be stored in flash and custom partition table is used add corresponding entry to your CSV. For examples, please see predefined partition table CSV descriptions in the components/partition_table directory.

NOTE: Many FreeRTOS configs

CRITICAL: Heap memory debugging https://docs.espressif.com/projects/esp-idf/en/stable/esp32/api-reference/kconfig.html#heap-memory-debugging

  - This is one of the key areas we wanted to be able to enable...

  - >>> CONFIG_HEAP_TRACING_OFF: Currently set to y in sdkconfig

    Other options: CONFIG_HEAP_TRACING_STANDALONE=y and CONFIG_HEAP_TRACING_TOHOST=y

  - >>> CONFIG_HEAP_TASK_TRACKING: Enables tracking the task responsible for each heap allocation.

    - This function depends on heap poisoning being enabled and adds four more bytes of overhead for each block allocated.

  - >>> CONFIG_HEAP_POISONING_LIGHT: Currently set to y in sdkconfig

    - Other options: CONFIG_HEAP_POISONING_BASIC (no poisoning) and CONFIG_HEAP_POISONING_COMPREHENSIVE

  - >>> CONFIG_HEAP_ABORT_WHEN_ALLOCATION_FAILS: Not currently sdk.

  - WARNING: many other options for v5.5.4 that aren't in sdkconfig...

NOTE: Log output

  - >>> CONFIG_LOG_DEFAULT_LEVEL: Specify how much output to see in logs by default. You can set lower verbosity level at runtime using esp_log_level_set() function if LOG_DYNAMIC_LEVEL_CONTROL is enabled.

    - This option only applies to logging from the app, the bootloader log level is fixed at compile time to the separate "Bootloader log verbosity" setting.

    - we're already doing this

  - >>> CONFIG_LOG_COLORS: Enable ANSI terminal color codes. In order to view these, your terminal program must support ANSI color codes.

  - >>> CONFIG_LOG_TIMESTAMP_SOURCE_RTOS: currently y in sdkconfig

    - milliseconds since boot

    - Other option in sdkconfig: CONFIG_LOG_TIMESTAMP_SOURCE_SYSTEM

NOTE: LWIP

  - >>> CRITICAL >>> CONFIG_LWIP_LOCAL_HOSTNAME: The default name this device will report to other devices on the network. Could be updated at runtime with esp_netif_set_hostname()

    - Currently set to "espressif"

    - TODO: Update hostname at runtime using esp_netif_set_hostname(). 6/8

    - NOTE: other lwip settings could help with network stability..

    - WARNING: CONFIG_LWIP_IPV6 is set to y in sdkconfig...
  
  - >>> CONFIG_LWIP_MAX_SOCKETS: Currently set to 16 in sdkconfig

  - >>> CONFIG_LWIP_DEBUG: Enables debugging (now called CONFIG_LWIP_STATS in v5+?)

NOTE: CONFIG_MQTT_* options exist in sdkconfig but we're not currently using any MQTT architecture at the moment...

  - see also CONFIG_MQTT_TRANSPORT_WEBSOCKET (currently y in sdkconfig)

  - could we use this as another way to have devices send a heartbeat? (instead of NATS)

NOTE: Bluetooth

  - >>> CRITICAL >>> CONFIG_BT_ENABLED: Select this option to enable Bluetooth and show the submenu with Bluetooth configuration choices.

    - sdkconfig has this as y.

    - IMPORTANT: ONE OF THE KEY GOALS WAS TO CREATE A CUSTOM BUILD THAT SETS THIS TO N TO SAVE HEAP!!!


Key sdkconfigs to look into:

  DONE: CONFIG_ESP32_DEFAULT_CPU_FREQ_240 CRITICAL
  DONE: CONFIG_ESP32_DEFAULT_CPU_FREQ_MHZ=240 CRITICAL
  DONE: CONFIG_BT_ENABLED CRITICAL (turn this off!)
  SKIP: (already off): CONFIG_PM_ENABLE CRITICAL (turn this off!)
  DONE: CONFIG_ESP32_RTC_CLK_SRC_INT_8MD256 CRITICAL (more accurate internal clock)
  DONE: CONFIG_MQTT_PROTOCOL_311=n CRITICAL
  DONE: CONFIG_MQTT_TRANSPORT_SSL=n CRITICAL
  DONE: CONFIG_MQTT_TRANSPORT_WEBSOCKET=n CRITICAL
  DONE: CONFIG_MQTT_TRANSPORT_WEBSOCKET_SECURE=n CRITICAL

  CONFIG_LWIP_LOCAL_HOSTNAME CRITICAL (set this to actual hostname on boot using specific function call that will overwrite this value)

  CONFIG_HEAP_TRACING_OFF CRITICAL
  CONFIG_HEAP_TASK_TRACKING CRITICAL
  CONFIG_HEAP_POISONING_LIGHT CRITICAL
  CONFIG_HEAP_ABORT_WHEN_ALLOCATION_FAILS CRITICAL

  CONFIG_ESP_EVENT_LOOP_PROFILING CRITICAL
  CONFIG_ESP_GDBSTUB_SUPPORT_TASKS CRITICAL
  CONFIG_LWIP_MAX_SOCKETS CRITICAL

  CONFIG_UNITY_ENABLE_COLOR
  CONFIG_UNITY_ENABLE_BACKTRACE_ON_FAIL

  CONFIG_BOOTLOADER_WDT_TIME_MS
  CONFIG_COMPILER_CXX_EXCEPTIONS
  CONFIG_I2C_ENABLE_DEBUG_LOG
  CONFIG_COMPILER_DUMP_RTL_FILES
  CONFIG_ESP_SYSTEM_EVENT_QUEUE_SIZE
  CONFIG_ESP_SYSTEM_EVENT_TASK_STACK_SIZE
  CONFIG_ESP_MAIN_TASK_STACK_SIZE
  CONFIG_ESP_INT_WDT
  CONFIG_ESP_INT_WDT_TIMEOUT_MS
  CONFIG_ESP_INT_WDT_CHECK_CPU1
  CONFIG_ESP_TASK_WDT_EN
  CONFIG_ESP_DEBUG_OCDAWARE
  CONFIG_ESP_BROWNOUT_DET
  CONFIG_ESP_BROWNOUT_DET_LVL_SEL
  CONFIG_LOG_COLORS
  CONFIG_LWIP_DEBUG 

Other configs to look into later:
  - CONFIG_COMPILER_STACK_CHECK_MODE
  - CONFIG_COMPILER_DISABLE_DEFAULT_ERRORS
  - CONFIG_LEDC_CTRL_FUNC_IN_IRAM
  - CONFIG_USJ_ENABLE_USB_SERIAL_JTAG
  - CONFIG_ETH_USE_ESP32_EMAC (NOTE: enabled by default)
  - CONFIG_ETH_USE_SPI_ETHERNET (NOTE: enabled by default)
  - CONFIG_ESP_NETIF_IP_LOST_TIMER_INTERVAL
  - CONFIG_ESP32_TRAX
  - CONFIG_ESP_DEBUG_STUBS_ENABLE
  - CONFIG_ESP_WIFI_SLP_DEFAULT_MAX_ACTIVE_TIME
  - CONFIG_LWIP_DHCPS

* 8:05PM With the original sdkconfig copied from arudino-esp32 from the feature/fws-custom-55d608e3-2.0.5 branch and after we removed rainmaker and camera configs, the following changes were made:

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  DONE: CONFIG_ESP32_DEFAULT_CPU_FREQ_240
  DONE: CONFIG_ESP32_DEFAULT_CPU_FREQ_MHZ=240
  DONE: CONFIG_BT_ENABLED=n
  SKIP: CONFIG_PM_ENABLE=n (already disabled)
  DONE: CONFIG_LOG_COLORS=y
  DONE: CONFIG_ESP32_RTC_CLK_SRC_INT_8MD256 (more accurate internal clock; currently CONFIG_ESP32_RTC_CLK_SRC_INT_RC)
  DONE: CONFIG_MQTT_PROTOCOL_311=n
  DONE: CONFIG_MQTT_TRANSPORT_SSL=n
  DONE: CONFIG_MQTT_TRANSPORT_WEBSOCKET=n
  DONE: CONFIG_MQTT_TRANSPORT_WEBSOCKET_SECURE=n
  DONE: Disable the following Arduino libraries:
  - AzureIoT (CONFIG_ARDUINO_SELECTIVE_AzureIoT)
  - BLE (CONFIG_ARDUINO_SELECTIVE_BLE)
  - BluetoothSerial (CONFIG_ARDUINO_SELECTIVE_BluetoothSerial)
  - SimpleBLE (CONFIG_ARDUINO_SELECTIVE_SimpleBLE)
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

WARNING: Even after removing rainmkr config, it comes back for some reason after copying our custom sdkconfig over defconfig.common.

Copying our custom edited sdkconfig over the one in the root for the lib builder as well.

Rmaker configs still appear. It may be coming in from IDF perhaps???

NOTE: Under "Include only specific Arduino libraries" you can specify which specific Arduino libraries should be included.
  - we're locking these versions in our platformio.ini file while also setting board_build.arduino.upstream_packages = no.

    ArduinoOTA @ 2.0.0
    Update @ 2.0.0                                                                ; for OTA
    HTTPClient @ 2.0.0
    Preferences @ 2.0.0
    Print @ 0.0.0
    FS @ 2.0.0                                                                    ; for file system
    SPIFFS @ 2.0.0                                                                ; for file system
    ESPmDNS	@ 2.0.0                                                               ; for WIFI
    WiFi @ 2.0.0
    WiFiClientSecure @ 2.0.0
    Wire @ 2.0.0                                                                  ; for I2C
    SPI @ 2.0.0  

Excluding the following in sdkconfig as we know we don't need them (could make things a little smaller in the end):
  - AzureIoT (CONFIG_ARDUINO_SELECTIVE_AzureIoT)
  - BLE (CONFIG_ARDUINO_SELECTIVE_BLE)
  - BluetoothSerial (CONFIG_ARDUINO_SELECTIVE_BluetoothSerial)
  - SimpleBLE (CONFIG_ARDUINO_SELECTIVE_SimpleBLE)

These are shown in the configs that start with `CONFIG_ARDUINO_SELECTIVE_`.

After modifying sdkconfig via menuconfig, copied sdkconfig over configs/defconfig.common.

We already backed it up along with defconfig.esp32 before wiping defconfig.esp32.

Generating a new build without passing `-b menuconfig`.

Had to delete esp-rainmakr from components as it came back.

New build was successful.

