# Development Log (LLM-readable)

> Structured change log optimized for AI consumption. Each entry records what changed, why, and which files were affected.
> **Prepend** new entries at the top.

---

## [v2.0] 2026-05-27 — Robot V1 framework: restructure project from blink to spherical robot

**Type**: refactor + feature
**Chip**: ESP32-S3
**IDF**: v6.0.1

### Summary
Complete project restructure from ESP-IDF blink example to spherical robot V1 software framework. Hardware selected (ST7789 display, INMP441 ×2 mics, stepper+TMC2209 motor), 4 new component skeletons created, all blink legacy code removed. V1 is framework-only — headers + CMakeLists + Kconfig, no implementation.

### Hardware selection
| Module | Part | Interface | GPIO |
|--------|------|-----------|------|
| Display | ST7789 1.54" 240×240 | SPI | MOSI:13, SCLK:14, CS:15, DC:16, RST:17, BL:18 |
| Mic ×2 | INMP441 | I2S | BCK:4, WS:5, DIN_L:6, DIN_R:7 |
| Motor driver | TMC2209 | STEP/DIR | STEP:10, DIR:11, EN:12 |
| Stepper | NEMA11 or 28BYJ-48 | - | 200 steps/rev, 16 μsteps |

### New components (skeleton only, no src/)
```
components/robot_core/
├── CMakeLists.txt          # REQUIRES: audio_locator motor_controller display_driver logger_wrapper
├── Kconfig                 # Enable/disable switch
└── include/robot_core.h    # State enum + init/start/stop/get_state

components/audio_locator/
├── CMakeLists.txt          # REQUIRES: esp_driver_i2s
├── Kconfig                 # I2S GPIO, sample rate
└── include/audio_locator.h # init/get_angle/is_sound_detected/deinit

components/motor_controller/
├── CMakeLists.txt          # REQUIRES: esp_driver_gpio
├── Kconfig                 # STEP/DIR/EN GPIO, steps/rev, microsteps
└── include/motor_controller.h # init/turn_to_angle/get_current_angle/return_to_center/deinit

components/display_driver/
├── CMakeLists.txt          # REQUIRES: esp_driver_spi
├── Kconfig                 # SPI GPIO (MOSI,SCLK,CS,DC,RST,BL)
└── include/display_driver.h # init/show_text/show_expression/clear/deinit
```

### Modified files
```
main/CMakeLists.txt          # SRCS: robot_main.c (was blink_example_main.c)
                             # REQUIRES: logger_wrapper robot_core (was logger_wrapper esp_driver_gpio)
CMakeLists.txt               # project(robot) — was project(blink)
main/Kconfig.projbuild       # Robot config (name, poll interval) — was blink LED config
sdkconfig.defaults           # CONFIG_ROBOT_NAME="V1" — was CONFIG_BLINK_LED_GPIO=y
sdkconfig.defaults.esp32s3   # CONFIG_ROBOT_NAME="V1-S3" — was CONFIG_BLINK_LED_STRIP=y
.vscode/settings.json        # Fixed clangd compile-commands path (blink→Project1_Robot)
.gitignore                   # Added .superpowers/
CLAUDE.md                    # Updated project name, architecture, build outputs
项目记录/项目架构.md          # Complete rewrite for robot V1
项目记录/版本记录.md          # Added v2.0 entry
项目记录/devlog.md           # This file — added v2.0 entry
```

### New files
```
main/robot_main.c            # app_main(): init logger → init robot_core → start → idle loop
docs/superpowers/specs/2026-05-27-robot-v1-design.md  # Full design spec
```

### Deleted files
```
main/blink_example_main.c    # Replaced by robot_main.c
pytest_blink.py              # Blink integration test, no longer relevant
sdkconfig.defaults.esp32     # ┐
sdkconfig.defaults.esp32c3   # │
sdkconfig.defaults.esp32c5   # │
sdkconfig.defaults.esp32c6   # │ 8 non-S3 chip defaults removed
sdkconfig.defaults.esp32c61  # │ (project is ESP32-S3 only)
sdkconfig.defaults.esp32h2   # │
sdkconfig.defaults.esp32p4   # │
sdkconfig.defaults.esp32s2   # ┘
```

### Robot state machine (robot_core)
```
IDLE → LISTENING → LOCATING → TURNING → FACE_PERSON → IDLE
```

### Architecture decisions
- **Coordinator pattern**: `robot_core` is the central state machine. It depends on all three hardware components. Components do NOT depend on each other.
- **Framework-first**: V1 creates the skeleton (headers, CMake, Kconfig) but leaves all SRCS empty. Each component's public API is fully defined; implementation follows in subsequent versions.
- **TDOA localization**: Dual INMP441 mics with known spacing. V1 only needs left/right discrimination, not precise angle.
- **Silent motor**: TMC2209 StealthChop for near-silent operation. Stepper chosen over servo for angle precision.
- **Single axis**: Pan-only (horizontal rotation) for V1. Tilt axis deferred to future iteration.
- **Minimal build retained**: MINIMAL_BUILD ON. All new components explicitly listed in REQUIRES chains.

### Sound localization principle
Dual mic TDOA (Time Difference of Arrival):
- Sound arrives at left/right mics with time delta Δt
- Mic spacing d ≈ 10-15cm, sound speed 340m/s
- Angle θ ≈ arcsin(Δt × 340 / d)
- V1: coarse left/center/right classification, then turn incrementally

### Git commits
```
f71e2bb feat: 搭建机器人 V1 项目框架
8a7e151 docs: 添加 V1 设计文档
```

### Previous state retained
- `logger_wrapper` component fully preserved (PSRAM ring buffer logging)
- ESP-IDF v6.0.1 toolchain and driver model
- MINIMAL_BUILD, PSRAM config, VS Code settings

---

## [v1.1] 2026-05-26 — Add logger_wrapper component

**Type**: feature
**Chip**: ESP32-S3
**IDF**: v6.0.1

### Summary
Created `logger_wrapper` component that wraps `esp_log` to dual-output logs: original console (UART) + PSRAM ring buffer. Existing code unchanged except one `#include` line.

### New files
```
components/logger_wrapper/
├── CMakeLists.txt                # idf_component_register(REQUIRES log heap freertos)
├── Kconfig                       # 4 options: enable, buf_size(32KB), tag_max(32), msg_max(256)
├── include/logger_wrapper.h      # Public API + redefined ESP_LOGx macros
├── src/logger_wrapper.c          # Ring buffer impl + _logger_wrapper_log()
└── logger_wrapper_priv.h         # entry_header_t (8B packed), ring_buffer_t
```

### Modified files
```
main/CMakeLists.txt          # +REQUIRES logger_wrapper esp_driver_gpio
main/blink_example_main.c    # #include "logger_wrapper.h" (was "esp_log.h")
                             # +logger_wrapper_init() in app_main()
CLAUDE.md                    # Fixed IDF paths, tool versions, added project context
```

### Architecture decisions
- **Macro wrapping**: `logger_wrapper.h` includes `esp_log.h`, then `#undef` + redefines `ESP_LOGE/W/I/D/V`. Each macro calls `_logger_wrapper_log()` (ring buffer) then `ESP_LOG_LEVEL()` (console). Both paths see same variadic args via macro expansion.
- **Ring buffer**: Fixed-size slots in PSRAM (`heap_caps_malloc(…, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT)`). Slot = `entry_header_t`(8B) + tag_max(32B) + msg_max(256B) = 296B per entry. Default 32KB buffer ≈ 110 entries.
- **Thread safety**: FreeRTOS mutex. `rb_dump()` releases mutex between callbacks to avoid deadlock if callback logs.
- **Graceful degradation**: If `heap_caps_malloc` fails or `logger_wrapper_init()` not called, `_logger_wrapper_log()` returns silently. Console logging still works.
- **Truncation**: Tag and message silently truncated to Kconfig MAX lengths.

### Public API
```c
esp_err_t logger_wrapper_init(void);                    // Alloc PSRAM, create mutex
void logger_wrapper_deinit(void);                       // Free PSRAM, delete mutex
uint32_t logger_wrapper_get_count(void);                 // Entries in ring buffer
esp_err_t logger_wrapper_dump(dump_cb_t cb, void *ctx); // Iterate oldest→newest
void logger_wrapper_clear(void);                        // Reset buffer
void _logger_wrapper_log(level, tag, format, ...);      // Internal, called by macros
```

### Build result
- `blink.bin`: 0x2e9d0 bytes (82% free in 1MB partition)
- Build command: `idf.py build` from PowerShell with manual PATH setup (see CLAUDE.md)

---

## [v1.0] 2026-05-26 — Initial state

**Type**: initial
**Chip**: ESP32-S3
**IDF**: v6.0.1

### Summary
ESP-IDF blink example, minimal modifications. GPIO LED on GPIO 8 or WS2812 LED strip on GPIO 38 via RMT.

### Key config
- MINIMAL_BUILD ON — only explicit REQUIRES components compiled
- PSRAM: octal 80MHz, GPIO30 CLK / GPIO26 CS, MALLOC mode
- espressif/led_strip v3.0.3 (managed component)
- Console: UART0, 115200 bps, COM11
- RGB LED: WS2812, GPIO 38, RMT backend

### Files
```
main/
├── CMakeLists.txt         # idf_component_register(SRCS blink_example_main.c INCLUDE_DIRS .)
├── blink_example_main.c   # app_main(): init LED, loop blink + ESP_LOGI
├── Kconfig.projbuild      # LED type, GPIO num, period
└── idf_component.yml      # espressif/led_strip: ^3.0.0
CMakeLists.txt             # MINIMAL_BUILD ON, project(blink)
sdkconfig                  # ESP32-S3, PSRAM enabled, LED strip config
```
