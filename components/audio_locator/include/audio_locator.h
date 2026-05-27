#pragma once

#include "esp_err.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

esp_err_t audio_locator_init(void);
float audio_locator_get_angle(void);
bool audio_locator_is_sound_detected(void);
esp_err_t audio_locator_deinit(void);

#ifdef __cplusplus
}
#endif
