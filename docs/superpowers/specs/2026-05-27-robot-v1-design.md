# 球形机器人 V1 设计文档

**日期**: 2026-05-27
**芯片**: ESP32-S3
**框架**: ESP-IDF v6.0.1

## 概述

初代球形机器人，灵感来源蔚来 NOMI。V1 核心能力：听声辨位 + 水平旋转转向声源。

## 硬件选型

| 模块 | 型号 | 接口 | GPIO |
|------|------|------|------|
| 主控 | ESP32-S3 | - | - |
| 显示屏 | ST7789 1.54" 240×240 | SPI | MOSI:13, SCLK:14, CS:15, DC:16, RST:17, BL:18 |
| 麦克风 ×2 | INMP441 | I2S | BCK:4, WS:5, DIN_L:6, DIN_R:7 |
| 电机驱动 | TMC2209 | STEP/DIR | STEP:10, DIR:11, EN:12 |
| 步进电机 | NEMA11 或 28BYJ-48 | - | 200 步/圈, 16 微步 |

## 机械结构

- 球形外壳 + 底座
- 单轴水平旋转（pan only）
- 双麦克风嵌于球体左右两侧，间距约 10-15cm

## 软件架构

```
robot_core (主状态机)
├── audio_locator   ← I2S 驱动, TDOA 声源定位
├── motor_controller ← TMC2209 步进电机控制
├── display_driver  ← ST7789 SPI 显示
└── logger_wrapper  ← [已有] PSRAM 日志环形缓冲
```

### 状态机

```
IDLE → LISTENING → LOCATING → TURNING → FACE_PERSON → IDLE
```

1. **IDLE**: 待机，等待声音触发
2. **LISTENING**: 正在采集音频
3. **LOCATING**: 计算声源角度
4. **TURNING**: 电机转动到目标角度
5. **FACE_PERSON**: 面向人，短暂停留后回到 IDLE

### 组件接口

**audio_locator**
```c
esp_err_t audio_locator_init(void);
float audio_locator_get_angle(void);     // 返回声源角度 (-180° ~ +180°)
bool audio_locator_is_sound_detected(void);
esp_err_t audio_locator_deinit(void);
```

**motor_controller**
```c
esp_err_t motor_controller_init(void);
esp_err_t motor_turn_to_angle(float degrees);
float motor_get_current_angle(void);
esp_err_t motor_return_to_center(void);
esp_err_t motor_controller_deinit(void);
```

**display_driver**
```c
esp_err_t display_init(void);
esp_err_t display_show_text(const char *text);
esp_err_t display_show_expression(display_expression_t expr);
esp_err_t display_clear(void);
esp_err_t display_deinit(void);
```

**robot_core**
```c
esp_err_t robot_core_init(void);
esp_err_t robot_core_start(void);
esp_err_t robot_core_stop(void);
robot_state_t robot_core_get_state(void);
```

## 声源定位原理

双麦克风 TDOA（到达时间差）：
- 声音到达左右两个麦克风有时间差 Δt
- 麦克风间距 d，声速 340m/s
- 角度 θ ≈ arcsin(Δt × 340 / d)
- V1 只需判断左右方向，不需要精确角度

## V1 范围

**包含**:
- 项目框架搭建（头文件、CMake、Kconfig）
- 各组件接口定义

**不包含**:
- 任何组件的内部实现
- 语音交互 / WiFi / 表情动画 / OTA

## 后续迭代

- 俯仰轴（tilt）
- 4 麦克风精确定位
- 表情动画引擎
- 语音唤醒/对话
