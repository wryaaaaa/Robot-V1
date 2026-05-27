// ============================================================
// Robot V1 球形外壳 — OpenSCAD 参数化模型
// 灵感: 蔚来 NOMI
// 球径 60mm，前脸截面平面装 ST7789，内置锂电池 + Type-C
// ============================================================

/* [主体尺寸] */
SPHERE_DIAMETER = 60;     // 球体外径 6cm
WALL_THICKNESS  = 2.5;    // 球壁厚度 (mm) — 小球的薄壁
TOLERANCE       = 0.3;    // 打印公差 (mm)

/* [显示屏 — ST7789 1.54" 模块] */
DISPLAY_PCB_W = 42;       // PCB 宽 (mm)
DISPLAY_PCB_H = 35;       // PCB 高 (mm)
DISPLAY_PCB_T = 1.6;      // PCB 厚 (mm)
DISPLAY_ACTIVE_W = 27;    // 显示区域宽 (mm)
DISPLAY_ACTIVE_H = 27;    // 显示区域高 (mm)

/* [锂电池 — 402030 3.7V 300mAh 软包] */
BATTERY_W = 30;           // 长 (mm)
BATTERY_H = 20;           // 宽 (mm)
BATTERY_T = 4;            // 厚 (mm)

/* [麦克风 — 双 INMP441] */
MIC_DIAMETER = 3;         // 拾音孔直径 (mm)

/* [Type-C 充电口 — TP4056 Type-C 模块] */
TYPEC_W = 9;              // 母座宽度 (mm)
TYPEC_H = 3.5;            // 母座高度 (mm)

/* [底座] */
BASE_DIAMETER = 60;       // 底座直径 (mm) — 与球同宽
BASE_HEIGHT   = 30;       // 底座高度 (mm)

/* [电机 — 28BYJ-48 步进电机] */
MOTOR_BODY_D = 28;        // 电机直径 (mm)
MOTOR_BODY_H = 20;        // 电机高度 (mm)

/* [ESP32-S3 安装柱] */
MOUNT_HOLE_D = 2.2;       // 螺丝孔 (mm) — M2 自攻
MOUNT_POST_D = 5;         // 安装柱外径 (mm)

// 渲染精度
$fn = 150;

// ---- 计算：前脸切割参数 ----
// 要容纳 42x35mm PCB，对角约 55mm，平面需要约 55mm 直径的圆
// 球半径 30mm，取切面半径为 28mm → 切面距球心 10.8mm
FACE_RADIUS = (DISPLAY_PCB_W + DISPLAY_PCB_H) / 4 + 4;  // ~24mm 半径(48mm直径)
FACE_OFFSET = sqrt(pow(SPHERE_DIAMETER / 2, 2) - pow(FACE_RADIUS, 2)); // 距球心距离

// ============================================================
// 1. 球体外壳 — 前脸截面切除 + 各开口
// ============================================================
module sphere_shell() {
    r = SPHERE_DIAMETER / 2;
    ir = r - WALL_THICKNESS;

    difference() {
        // 外壳
        sphere(d = SPHERE_DIAMETER);

        // 挖空
        sphere(d = SPHERE_DIAMETER - WALL_THICKNESS * 2);

        // 前脸截面 — 一刀切出平面
        translate([FACE_OFFSET, 0, 0])
            cube([r * 2, r * 2, r * 2], center = true);

        // 显示窗口 (从截面再往内挖)
        translate([r - WALL_THICKNESS + 1, 0, 0])
            cube([WALL_THICKNESS + 4, DISPLAY_ACTIVE_W + 4, DISPLAY_ACTIVE_H + 4], center = true);

        // 底部 — 与底座电机连接的开口
        translate([0, 0, -r - 1])
            cylinder(d = 25, h = r);

        // 麦克风拾音孔 (左右 — 球体两侧)
        for (side = [-1, 1]) {
            rotate([20 * side, 0, 0])
            translate([0, r - 2, 0])
                rotate([90, 0, 0])
                cylinder(d = MIC_DIAMETER, h = WALL_THICKNESS + 2, center = true);
        }

        // Type-C 开口 (球背底部)
        translate([-r + WALL_THICKNESS, 0, -12])
            cube([WALL_THICKNESS + 3, TYPEC_W + 2, TYPEC_H + 2], center = true);
    }

    // 四个安装柱 (显示屏 PCB 固定)
    for (x = [-(DISPLAY_PCB_W / 2 - 2), (DISPLAY_PCB_W / 2 - 2)]) {
        for (z = [-(DISPLAY_PCB_H / 2 - 2), (DISPLAY_PCB_H / 2 - 2)]) {
            // 安装柱起点在球壳内壁
            translate([FACE_OFFSET + 0.5, x, z])
                rotate([0, 90, 0])
                cylinder(d = MOUNT_POST_D, h = WALL_THICKNESS + DISPLAY_PCB_T + 3);
        }
    }

    // Type-C 模块安装槽 (球内壁)
    translate([-r + WALL_THICKNESS, 0, -12])
        cube([WALL_THICKNESS + 3, TYPEC_W + 4, TYPEC_H + 8], center = true);
}

// ============================================================
// 2. 显示面板框 — 卡在球体前脸截面上的装饰框
// ============================================================
module face_frame() {
    difference() {
        // 与球面匹配的弧形框
        intersection() {
            sphere(d = SPHERE_DIAMETER);
            translate([FACE_OFFSET - 1, 0, 0])
                cube([3, FACE_RADIUS * 2, FACE_RADIUS * 2], center = true);
        }

        // 显示窗口
        translate([SPHERE_DIAMETER / 2 + 1, 0, 0])
            cube([WALL_THICKNESS + 4, DISPLAY_ACTIVE_W, DISPLAY_ACTIVE_H], center = true);
    }
}

// ============================================================
// 3. 底座 — 含电机座和轴承位
// ============================================================
module base() {
    difference() {
        union() {
            // 底座桶身
            cylinder(d = BASE_DIAMETER, h = BASE_HEIGHT);

            // 底部防滑圈
            translate([0, 0, 2])
                cylinder(d = BASE_DIAMETER - 2, h = 3);
        }

        // 内部挖空
        translate([0, 0, 4])
            cylinder(d = BASE_DIAMETER - 6, h = BASE_HEIGHT - 2);

        // 电机安装腔
        translate([0, 0, BASE_HEIGHT - MOTOR_BODY_H])
            cylinder(d = MOTOR_BODY_D + 4, h = MOTOR_BODY_H + 8);

        // 电机轴孔
        translate([0, 0, BASE_HEIGHT - 3])
            cylinder(d = 6, h = 10);

        // 电机螺丝孔 (4个)
        for (angle = [0, 90, 180, 270]) {
            translate([cos(angle) * (MOTOR_BODY_D / 2 - 1.5),
                       sin(angle) * (MOTOR_BODY_D / 2 - 1.5),
                       BASE_HEIGHT - 3])
                cylinder(d = 2, h = 10);
        }

        // 侧面走线孔
        translate([BASE_DIAMETER / 2 - 4, 0, 10])
            rotate([0, 90, 0])
            cylinder(d = 6, h = 12);
    }
}

// ============================================================
// 4. 电池支架 — 球内底部
// ============================================================
module battery_holder() {
    difference() {
        union() {
            cube([BATTERY_W + 6, BATTERY_H + 6, BATTERY_T + 3], center = true);
            // 安装耳
            for (y = [-(BATTERY_H / 2 + 4), (BATTERY_H / 2 + 4)]) {
                translate([0, y, 0])
                    cube([BATTERY_W + 10, 4, 2], center = true);
            }
        }
        // 电池槽
        translate([0, 0, 1])
            cube([BATTERY_W + TOLERANCE, BATTERY_H + TOLERANCE, BATTERY_T + 1], center = true);
    }
}

// ============================================================
// 5. 完整装配预览
// ============================================================
module robot_assembly() {
    // 底座
    color("DimGray") base();

    // 球体
    color("White", 0.6) sphere_shell();

    // 显示框
    color("DimGray") face_frame();

    // 电池 (球内下部)
    translate([-5, 0, -18])
        color("RoyalBlue", 0.7)
        cube([BATTERY_W, BATTERY_H, BATTERY_T], center = true);

    // ESP32 主板示意 (球内中部)
    translate([-10, 0, 2])
        color("ForestGreen", 0.6)
        cube([55, 28, 2], center = true);

    // 电机示意
    translate([0, 0, BASE_HEIGHT - MOTOR_BODY_H])
        color("Silver", 0.5)
        cylinder(d = MOTOR_BODY_D, h = MOTOR_BODY_H);
}

// ============================================================
// 分件导出
// ============================================================

// 完整预览
robot_assembly();

// 分件 — 逐个取消注释导出 STL:
// sphere_shell();     // 球体外壳
// face_frame();       // 显示面板框
// base();             // 底座+电机座
// battery_holder();   // 电池支架
