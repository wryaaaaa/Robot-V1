#include "robot_core.h"

static robot_state_t s_state = ROBOT_STATE_IDLE;

esp_err_t robot_core_init(void)
{
    s_state = ROBOT_STATE_IDLE;
    return ESP_OK;
}

esp_err_t robot_core_start(void)
{
    s_state = ROBOT_STATE_LISTENING;
    return ESP_OK;
}

esp_err_t robot_core_stop(void)
{
    s_state = ROBOT_STATE_IDLE;
    return ESP_OK;
}

robot_state_t robot_core_get_state(void)
{
    return s_state;
}
