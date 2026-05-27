// ============================================================
// Robot V1 — 截球体智能交互终端 CAD 概念模型
// 参考: 蔚来 NOMI
// 球体外径 100mm，两次平面截切，全电路内置球体
// ============================================================

/* ============================================================
   [ 主体几何参数 ]
   ============================================================ */
SPHERE_DIAMETER = 100;    // 球体外径 (mm)
WALL_THICKNESS  = 3.0;    // 壳体厚度 (mm)
TOLERANCE       = 0.3;    // 打印配合公差 (mm)

// 前截面 — 显示屏安装平面
FACE_RADIUS     = 25;     // 前截面圆半径 (mm) — 留出 50mm 直径安装面
// 前截面距球心的 X 距离 = sqrt(50² - 25²) ≈ 43.3mm
FACE_OFFSET_X   = sqrt(pow(SPHERE_DIAMETER / 2, 2) - pow(FACE_RADIUS, 2));

// 底截面 — 底座连接/旋转机构安装平面
BASE_CUT_RADIUS = 17.5;   // 底截面圆半径 (mm) — 35mm 直径连接面
// 底截面距球心的 Z 距离 = sqrt(50² - 17.5²) ≈ 46.8mm
BASE_CUT_OFFSET_Z = sqrt(pow(SPHERE_DIAMETER / 2, 2) - pow(BASE_CUT_RADIUS, 2));

/* ============================================================
   [ 显示屏参数 — ST7789 1.54" 模块 ]
   ============================================================ */
DISPLAY_PCB_W   = 42;     // 模块 PCB 宽
DISPLAY_PCB_H   = 35;     // 模块 PCB 高
DISPLAY_PCB_T   = 1.6;    // PCB 板厚
DISPLAY_ACTIVE_W = 27;    // 显示区域宽 (可视区)
DISPLAY_ACTIVE_H = 27;    // 显示区域高 (可视区)
DISPLAY_GLASS_T = 2.0;    // 前面板玻璃/亚克力厚
DISPLAY_BEZEL_W = 2.5;    // 显示窗边框宽

/* ============================================================
   [ 内部元件尺寸 ]
   ============================================================ */
// ESP32-S3-DevKitC
ESP32_BOARD_W = 55;       ESP32_BOARD_H = 28;    ESP32_BOARD_T = 13;  // 含元件高度

// 锂电池 — 3.7V 1500-2000mAh 软包 (100mm 球有足够空间)
BATTERY_W = 55;           BATTERY_H = 35;        BATTERY_T = 8;

// TMC2209 步进驱动模块
TMC2209_W = 15;           TMC2209_H = 20;        TMC2209_T = 3;

// TP4056 Type-C 充电模块
TYPEC_MOD_W = 25;         TYPEC_MOD_H = 18;      TYPEC_MOD_T = 5;
TYPEC_CUTOUT_W = 9;                              TYPEC_CUTOUT_H = 3.5;

/* ============================================================
   [ 底座 & 旋转机构 ]
   ============================================================ */
BASE_DIAMETER   = 75;     // 底座外径 — 比截球稍小，视觉轻盈
BASE_HEIGHT     = 22;     // 底座高度
BEARING_OD      = 32;     // 推力轴承/旋转轴承座外径
BEARING_ID      = 20;     // 轴承内径 (走线通道)
MOTOR_BODY_D    = 28;     // 28BYJ-48 步进电机直径
MOTOR_BODY_H    = 20;     // 电机高度
MOTOR_SHAFT_D   = 5;      // 电机轴径
ROTATION_HUB_D  = 22;     // 球体底部旋转连接毂外径

/* ============================================================
   [ 紧固件 ]
   ============================================================ */
SCREW_HOLE_D    = 2.2;    // M2 自攻螺丝底孔
SCREW_POST_D    = 5.5;    // 螺丝柱外径
SCREW_POST_H    = 6;      // 螺丝柱高度
ALIGN_PIN_D     = 2.0;    // 定位销直径

// ---- 渲染精度 ----
$fn = 180;

// ============================================================
// 辅助：截球体主体几何体
// ============================================================
module truncated_sphere_body() {
    r = SPHERE_DIAMETER / 2;

    difference() {
        sphere(d = SPHERE_DIAMETER);

        // 前截面切除
        translate([FACE_OFFSET_X, 0, 0])
            cube([r * 2, r * 3, r * 3], center = true);

        // 底截面切除
        translate([0, 0, -BASE_CUT_OFFSET_Z])
            cube([r * 3, r * 3, r * 2], center = true);
    }
}

module truncated_sphere_cavity() {
    r = SPHERE_DIAMETER / 2 - WALL_THICKNESS;

    difference() {
        sphere(d = SPHERE_DIAMETER - WALL_THICKNESS * 2);

        // 前截面切内部
        translate([FACE_OFFSET_X - WALL_THICKNESS, 0, 0])
            cube([r * 2, r * 3, r * 3], center = true);

        // 底截面切内部 — 留出连接毂穿过的孔
        translate([0, 0, -BASE_CUT_OFFSET_Z + WALL_THICKNESS])
            cube([r * 3, r * 3, r * 2], center = true);
    }
}

// ============================================================
// 1. 前壳 — 带显示面板安装结构
// ============================================================
module front_shell() {
    r = SPHERE_DIAMETER / 2;

    difference() {
        // 前壳主体：截球前半部分
        intersection() {
            truncated_sphere_body();
            // 前后分模线：球体赤道附近
            translate([-r, -r - 1, -r - 1])
                cube([r * 2, r * 2, r * 2 + 2]);
        }

        // 挖空内部
        intersection() {
            truncated_sphere_cavity();
            translate([-r - 1, -r - 1, -r - 1])
                cube([r * 2 + 2, r * 2 + 2, r * 2 + 2]);
        }

        // 显示屏可视窗口 (前截面挖透)
        hull() {
            translate([r - 1, -DISPLAY_ACTIVE_W / 2 - DISPLAY_BEZEL_W, -DISPLAY_ACTIVE_H / 2 - DISPLAY_BEZEL_W])
                rotate([0, 90, 0])
                cylinder(r = 6, h = WALL_THICKNESS * 2, center = true);
            translate([r - 1,  DISPLAY_ACTIVE_W / 2 + DISPLAY_BEZEL_W, -DISPLAY_ACTIVE_H / 2 - DISPLAY_BEZEL_W])
                rotate([0, 90, 0])
                cylinder(r = 6, h = WALL_THICKNESS * 2, center = true);
            translate([r - 1, -DISPLAY_ACTIVE_W / 2 - DISPLAY_BEZEL_W,  DISPLAY_ACTIVE_H / 2 + DISPLAY_BEZEL_W])
                rotate([0, 90, 0])
                cylinder(r = 6, h = WALL_THICKNESS * 2, center = true);
            translate([r - 1,  DISPLAY_ACTIVE_W / 2 + DISPLAY_BEZEL_W,  DISPLAY_ACTIVE_H / 2 + DISPLAY_BEZEL_W])
                rotate([0, 90, 0])
                cylinder(r = 6, h = WALL_THICKNESS * 2, center = true);
        }
    }

    // 前面板安装沉台 (显示屏 PCB 从内放入)
    translate([FACE_OFFSET_X + WALL_THICKNESS / 2, 0, 0])
        difference() {
            cube([DISPLAY_PCB_T + DISPLAY_GLASS_T + 1.5, DISPLAY_PCB_W + 3, DISPLAY_PCB_H + 3], center = true);
            cube([DISPLAY_PCB_T + DISPLAY_GLASS_T + 1.5, DISPLAY_PCB_W, DISPLAY_PCB_H], center = true);
        }
}

// ============================================================
// 2. 后壳 — 含内部支架、Type-C 口、麦克风孔
// ============================================================
module rear_shell() {
    r = SPHERE_DIAMETER / 2;

    difference() {
        union() {
            // 后壳主体：截球后半部分
            intersection() {
                truncated_sphere_body();
                translate([-r, -r - 1, -r - 1])
                    cube([r * 2 + 1, r * 2 + 2, r * 2 + 2]);
            }

            // 内部主板安装柱 (左右两排，ESP32 竖装)
            for (y = [-(ESP32_BOARD_W / 2 - 4), (ESP32_BOARD_W / 2 - 4)]) {
                translate([-20, y, 8])
                    cylinder(d = SCREW_POST_D, h = SCREW_POST_H);
            }

            // 电池仓侧壁
            for (side = [-1, 1]) {
                translate([-10, side * (BATTERY_H / 2 + 1), -5])
                    cube([BATTERY_W + 4, 2, BATTERY_T + 4], center = true);
            }

            // Type-C 充电模块安装槽 (后壳底部)
            translate([-r + WALL_THICKNESS + 1, 0, -15])
                cube([WALL_THICKNESS + 3, TYPEC_MOD_W + 4, TYPEC_MOD_H + 4], center = true);

            // 球底旋转连接毂 (与底座电机连接的结构)
            translate([0, 0, -BASE_CUT_OFFSET_Z])
                cylinder(d = ROTATION_HUB_D, h = 8);

            // 分模线卡扣/定位销
            for (angle = [45, 135, 225, 315]) {
                ax = cos(angle) * sqrt(pow(r - WALL_THICKNESS, 2) - pow(r * 0.6, 2));
                ay = sin(angle) * sqrt(pow(r - WALL_THICKNESS, 2) - pow(r * 0.6, 2));
                translate([0, ay * 0.6, r * 0.15 * (angle > 180 ? -1 : 1)])
                    rotate([90, 0, 0])
                    cylinder(d = ALIGN_PIN_D, h = 5, center = true);
            }
        }

        // 挖空内部
        intersection() {
            truncated_sphere_cavity();
            translate([-r - 1, -r - 1, -r - 1])
                cube([r * 2 + 2, r * 2 + 2, r * 2 + 2]);
        }

        // 主板螺丝底孔
        for (y = [-(ESP32_BOARD_W / 2 - 4), (ESP32_BOARD_W / 2 - 4)]) {
            translate([-20, y, 8])
                cylinder(d = SCREW_HOLE_D, h = SCREW_POST_H + 2);
        }

        // Type-C 开口
        translate([-r + 1, 0, -15])
            cube([WALL_THICKNESS + 4, TYPEC_CUTOUT_W, TYPEC_CUTOUT_H], center = true);

        // 麦克风拾音孔 × 2 (球体两侧)
        for (side = [-1, 1]) {
            rotate([15 * side, 0, 0])
            translate([0, r - 2, 0])
                rotate([90, 0, 0])
                cylinder(d = 3.5, h = WALL_THICKNESS + 3, center = true);
        }

        // 前壳定位销配合孔
        for (angle = [45, 135, 225, 315]) {
            ay = sin(angle) * sqrt(pow(r - WALL_THICKNESS, 2) - pow(r * 0.6, 2));
            translate([2, ay * 0.6, r * 0.15 * (angle > 180 ? -1 : 1)])
                rotate([90, 0, 0])
                cylinder(d = ALIGN_PIN_D + 0.3, h = 5, center = true);
        }

        // 螺丝柱配合孔 (4颗，沿分模线)
        for (angle = [30, 150, 210, 330]) {
            az = cos(angle) * sqrt(pow(r - WALL_THICKNESS, 2) - pow(r * 0.7, 2));
            ax = sin(angle) * sqrt(pow(r - WALL_THICKNESS, 2) - pow(r * 0.7, 2));
            translate([5, ax * 0.7, az * 0.7])
                rotate([90, 0, 90])
                cylinder(d = SCREW_HOLE_D, h = 8, center = true);
        }

        // 底截面中心孔 — 与底座电机轴配合
        translate([0, 0, -BASE_CUT_OFFSET_Z - 1])
            cylinder(d = MOTOR_SHAFT_D + 1, h = 20);

        // 旋转毂内部走线通道 (斜向通入球体)
        translate([0, 0, -BASE_CUT_OFFSET_Z - 0.5])
            cylinder(d = 8, h = 25);
    }
}

// ============================================================
// 3. 前面板 — 黑色亚克力/玻璃盖板 (贴合前截面)
// ============================================================
module face_panel() {
    difference() {
        // 面板主体 — 圆角矩形 (与前截面对齐)
        translate([FACE_OFFSET_X + WALL_THICKNESS / 2 + 0.5, 0, 0])
            hull() {
                for (sx = [-1, 1], sy = [-1, 1]) {
                    translate([0,
                               sx * (DISPLAY_PCB_W / 2 + 1.5 - 5),
                               sy * (DISPLAY_PCB_H / 2 + 1.5 - 5)])
                        cylinder(r = 5, h = DISPLAY_GLASS_T, center = true);
                }
            }

        // 显示窗口
        translate([FACE_OFFSET_X + WALL_THICKNESS + 1, 0, 0])
            hull() {
                for (sx = [-1, 1], sy = [-1, 1]) {
                    translate([0,
                               sx * (DISPLAY_ACTIVE_W / 2 - 3),
                               sy * (DISPLAY_ACTIVE_H / 2 - 3)])
                        cylinder(r = 3, h = DISPLAY_GLASS_T + 4, center = true);
                }
            }
    }
}

// ============================================================
// 4. 底座 — 电机安装仓 + 旋转轴承支撑
// ============================================================
module base_unit() {
    difference() {
        union() {
            // 底座主体 — 圆台形
            cylinder(d1 = BASE_DIAMETER, d2 = BASE_DIAMETER - 6, h = BASE_HEIGHT);

            // 轴承座凸台
            translate([0, 0, BASE_HEIGHT])
                cylinder(d = BEARING_OD + 8, h = 8);

            // 底部配重/防滑圈
            translate([0, 0, 1])
                cylinder(d = BASE_DIAMETER - 4, h = 3);
        }

        // 内腔挖空
        translate([0, 0, 4])
            cylinder(d = BASE_DIAMETER - 8, h = BASE_HEIGHT - 2);

        // 轴承安装孔
        translate([0, 0, BASE_HEIGHT + 4])
            cylinder(d = BEARING_OD + TOLERANCE * 2, h = 8);

        // 电机安装腔
        translate([0, 0, BASE_HEIGHT - MOTOR_BODY_H])
            cylinder(d = MOTOR_BODY_D + 3, h = MOTOR_BODY_H + 8);

        // 电机轴通孔
        translate([0, 0, BASE_HEIGHT - 3])
            cylinder(d = MOTOR_SHAFT_D + 1, h = 14);

        // 电机固定螺丝 × 4
        for (angle = [0, 90, 180, 270]) {
            translate([cos(angle) * (MOTOR_BODY_D / 2 - 1.8),
                       sin(angle) * (MOTOR_BODY_D / 2 - 1.8),
                       BASE_HEIGHT - 3])
                cylinder(d = 2.0, h = 12);
        }

        // 侧面出线孔
        translate([BASE_DIAMETER / 2 - 4, 0, BASE_HEIGHT / 2])
            rotate([0, 90, 0])
            cylinder(d = 7, h = 14);
    }
}

// ============================================================
// 5. 内部元件示意 (装配预览用)
// ============================================================
module esp32_board() {
    color("#2d5a1e", 0.85)
    difference() {
        cube([ESP32_BOARD_W, ESP32_BOARD_H, ESP32_BOARD_T], center = true);
        // 螺丝孔
        for (y = [-(ESP32_BOARD_W / 2 - 4), (ESP32_BOARD_W / 2 - 4)]) {
            translate([0, y, ESP32_BOARD_T / 2])
                cylinder(d = SCREW_HOLE_D, h = 3, center = true);
        }
    }
}

module battery() {
    color("#1a3a6b", 0.7)
        cube([BATTERY_W, BATTERY_H, BATTERY_T], center = true);
}

module motor() {
    color("#888")
        cylinder(d = MOTOR_BODY_D, h = MOTOR_BODY_H);
    color("#ccc")
        translate([0, 0, MOTOR_BODY_H])
        cylinder(d = MOTOR_SHAFT_D, h = 12);
}

// ============================================================
// 6. 完整装配预览
// ============================================================
module robot_assembly_show() {
    // 后壳
    color("#2a2a2a") rear_shell();

    // 前壳 (半透明)
    color("#333", 0.35) front_shell();

    // 前面板
    color("#111") face_panel();

    // 底座
    color("#3a3a3a") base_unit();

    // 内部元件位置示意
    translate([-18, 0, -5])  esp32_board();
    translate([5, 0, -10])   battery();

    // 电机 (底座内)
    translate([0, 0, BASE_HEIGHT - MOTOR_BODY_H])
        motor();
}

// ============================================================
// 分件导出区
// ============================================================

// 完整预览 (默认)
robot_assembly_show();

// 分件 — 逐个取消注释导出:
// front_shell();      // 前壳
// rear_shell();       // 后壳
// face_panel();       // 前面板 (亚克力/玻璃)
// base_unit();        // 底座
