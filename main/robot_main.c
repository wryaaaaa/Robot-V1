#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "logger_wrapper.h"
#include "robot_core.h"
#include "uart_comm.h"

static const char *TAG = "robot_main";

void app_main(void)
{
    ESP_ERROR_CHECK(logger_wrapper_init());
    ESP_LOGI(TAG, "Robot V1 starting...");

    if (robot_core_init() != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize robot core");
        return;
    }

    if (robot_core_start() != ESP_OK) {
        ESP_LOGE(TAG, "Failed to start robot core");
        return;
    }

    if (uart_comm_init() != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize UART communication");
        return;
    }

    ESP_LOGI(TAG, "Robot V1 running");

    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
