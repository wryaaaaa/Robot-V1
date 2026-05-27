#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    ROBOT_STATE_IDLE = 0,
    ROBOT_STATE_LISTENING,
    ROBOT_STATE_LOCATING,
    ROBOT_STATE_TURNING,
    ROBOT_STATE_FACE_PERSON,
} robot_state_t;

esp_err_t robot_core_init(void);
esp_err_t robot_core_start(void);
esp_err_t robot_core_stop(void);
robot_state_t robot_core_get_state(void);

#ifdef __cplusplus
}
#endif
