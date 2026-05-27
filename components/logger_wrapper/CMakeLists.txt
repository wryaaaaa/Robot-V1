idf_component_register(
    SRCS "src/logger_wrapper.c"
    INCLUDE_DIRS "include"
    PRIV_INCLUDE_DIRS "."
    REQUIRES log heap freertos
)
