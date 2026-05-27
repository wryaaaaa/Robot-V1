#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

esp_err_t motor_controller_init(void);
esp_err_t motor_turn_to_angle(float degrees);
float motor_get_current_angle(void);
esp_err_t motor_return_to_center(void);
esp_err_t motor_controller_deinit(void);

#ifdef __cplusplus
}
#endif
