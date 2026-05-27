idf_component_register(
    SRCS "src/robot_core.c"
    INCLUDE_DIRS "include"
    REQUIRES audio_locator motor_controller display_driver logger_wrapper
)
