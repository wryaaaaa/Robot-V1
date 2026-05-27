#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    DISPLAY_EXPR_IDLE = 0,
    DISPLAY_EXPR_LISTENING,
    DISPLAY_EXPR_THINKING,
    DISPLAY_EXPR_HAPPY,
    DISPLAY_EXPR_CONFUSED,
} display_expression_t;

esp_err_t display_init(void);
esp_err_t display_show_text(const char *text);
esp_err_t display_show_expression(display_expression_t expr);
esp_err_t display_clear(void);
esp_err_t display_deinit(void);

#ifdef __cplusplus
}
#endif
