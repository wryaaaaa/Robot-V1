idf_component_register(
    SRCS "src/uart_comm.c"
    INCLUDE_DIRS "include"
    REQUIRES esp_driver_uart robot_core
)
