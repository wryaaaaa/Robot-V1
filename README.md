| 支持芯片 | ESP32 | ESP32-C2 | ESP32-C3 | ESP32-C5 | ESP32-C6 | ESP32-C61 | ESP32-H2 | ESP32-H21 | ESP32-H4 | ESP32-P4 | ESP32-S2 | ESP32-S3 |
| -------- | ----- | -------- | -------- | -------- | -------- | --------- | -------- | --------- | -------- | -------- | -------- | -------- |

> 当前项目基于 **ESP32-S3**。

# 球形机器人 V1（Robot V1）

球形机器人初代项目，灵感来源蔚来 NOMI。基于 ESP32-S3 主控，实现听声辨位与水平旋转转向功能。

## 核心功能

- **听声辨位**：双 INMP441 I2S MEMS 麦克风，基于 TDOA（到达时间差）判断声源左右方向
- **旋转转向**：步进电机 + TMC2209 静音驱动，单轴水平旋转，转向声源
- **显示屏**：ST7789 1.54" 方形 LCD（240×240），SPI 接口，展示机器人状态和表情
- **日志记录**：PSRAM 环形缓冲区存储运行日志，支持离线读取

## 硬件要求

- ESP32-S3 开发板（推荐 ESP32-S3-DevKitC v1.1）
- ST7789 显示屏（1.54" 240×240 SPI）
- INMP441 MEMS 麦克风 × 2
- 步进电机（NEMA11 或 28BYJ-48）+ TMC2209 驱动模块
- USB 数据线（供电 + 烧录）

## 使用方法

### 配置项目

在项目目录下运行配置菜单：

```powershell
idf.py menuconfig
```

在 `Robot Configuration` 菜单中可配置机器人名称和传感器轮询间隔。

各组件的引脚分配和参数可分别在对应子菜单中配置：
- `Audio Locator Configuration`：麦克风 I2S 引脚和采样率
- `Motor Controller Configuration`：电机 STEP/DIR/EN 引脚和微步数
- `Display Driver Configuration`：显示屏 SPI 引脚

### 构建与烧录

```powershell
# 构建
idf.py build

# 烧录并查看串口输出
idf.py -p COM11 flash monitor
```

（按 `Ctrl-]` 退出串口监视器）

### 设置芯片目标

如需切换芯片型号：

```powershell
idf.py set-target <芯片名称>
```

## 预期输出

启动后串口输出示例：

```
I (315) robot_main: Robot V1 starting...
I (325) robot_main: Robot V1 running
```

> 注意：当前版本（V2.0）为框架搭建阶段，各组件仅定义接口，尚未实现内部逻辑。因此机器人暂不会实际响应声音或转动。

## 项目结构

```
Project1_Robot/
├── main/                       # 主程序入口
│   ├── robot_main.c            # app_main() 初始化流程
│   └── CMakeLists.txt
├── components/                 # 自定义组件
│   ├── robot_core/             # 主状态机
│   ├── audio_locator/          # 声源定位
│   ├── motor_controller/       # 电机控制
│   ├── display_driver/         # 显示屏驱动
│   └── logger_wrapper/         # 日志包装器
├── docs/                       # 设计文档
└── 项目记录/                   # 版本记录与架构文档
```

## 版本历史

详见 [项目记录/版本记录.md](项目记录/版本记录.md)。

| 版本 | 日期 | 内容 |
|------|------|------|
| v2.0 | 2026-05-27 | 重构为机器人项目，搭建组件框架 |
| v1.1 | 2026-05-26 | 新增 logger_wrapper 日志包装组件 |
| v1.0 | 2026-05-26 | 基于 ESP-IDF blink 示例初始化 |

## 问题排查

- 构建失败：确认 ESP-IDF v6.0.1 环境已正确配置，参考 [CLAUDE.md](../CLAUDE.md)
- 烧录失败：检查串口号是否正确（当前 COM11），确认设备已进入下载模式

如有技术问题，请在 [GitHub Issues](https://github.com/wryaaaaa/Robot-V1/issues) 提交。
