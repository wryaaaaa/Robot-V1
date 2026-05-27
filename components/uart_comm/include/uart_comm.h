#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

esp_err_t uart_comm_init(void);
esp_err_t uart_comm_send_status(void);
esp_err_t uart_comm_deinit(void);

#ifdef __cplusplus
}
#endif
