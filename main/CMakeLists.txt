idf_component_register(SRCS "robot_main.c"
                       INCLUDE_DIRS "."
                       REQUIRES logger_wrapper robot_core uart_comm)
