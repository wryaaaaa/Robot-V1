#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/timers.h"
#include "driver/uart.h"
#include "esp_log.h"
#include "uart_comm.h"
#include "robot_core.h"
#include "sdkconfig.h"

static const char *TAG = "uart_comm";

static TimerHandle_t s_timer = NULL;

static const char *state_to_str(robot_state_t state)
{
    switch (state) {
    case ROBOT_STATE_IDLE:         return "IDLE";
    case ROBOT_STATE_LISTENING:    return "LISTENING";
    case ROBOT_STATE_LOCATING:     return "LOCATING";
    case ROBOT_STATE_TURNING:      return "TURNING";
    case ROBOT_STATE_FACE_PERSON:  return "FACE_PERSON";
    default:                       return "UNKNOWN";
    }
}

static void send_line(const char *line)
{
    uart_write_bytes(CONFIG_UART_COMM_PORT_NUM, line, strlen(line));
    uart_write_bytes(CONFIG_UART_COMM_PORT_NUM, "\r\n", 2);
}

esp_err_t uart_comm_send_status(void)
{
    robot_state_t state = robot_core_get_state();
    static uint32_t boot_ticks = 0;
    if (boot_ticks == 0) {
        boot_ticks = xTaskGetTickCount();
    }
    uint32_t uptime_s = (xTaskGetTickCount() - boot_ticks) * portTICK_PERIOD_MS / 1000;

    char buf[128];
    snprintf(buf, sizeof(buf),
             "RBT:state=%s,uptime=%lu",
             state_to_str(state), (unsigned long)uptime_s);

    send_line(buf);
    return ESP_OK;
}

static void timer_callback(TimerHandle_t timer)
{
    (void)timer;
    uart_comm_send_status();
}

esp_err_t uart_comm_init(void)
{
    uart_config_t uart_config = {
        .baud_rate  = CONFIG_UART_COMM_BAUD_RATE,
        .data_bits  = UART_DATA_8_BITS,
        .parity     = UART_PARITY_DISABLE,
        .stop_bits  = UART_STOP_BITS_1,
        .flow_ctrl  = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };

    ESP_ERROR_CHECK(uart_driver_install(CONFIG_UART_COMM_PORT_NUM,
                                         1024, 256, 0, NULL, 0));
    ESP_ERROR_CHECK(uart_param_config(CONFIG_UART_COMM_PORT_NUM, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(CONFIG_UART_COMM_PORT_NUM,
                                   CONFIG_UART_COMM_TX_GPIO,
                                   CONFIG_UART_COMM_RX_GPIO,
                                   UART_PIN_NO_CHANGE,
                                   UART_PIN_NO_CHANGE));

    s_timer = xTimerCreate("uart_timer",
                           pdMS_TO_TICKS(CONFIG_UART_COMM_INTERVAL_MS),
                           pdTRUE,
                           NULL,
                           timer_callback);
    if (s_timer == NULL) {
        ESP_LOGE(TAG, "Failed to create UART timer");
        return ESP_ERR_NO_MEM;
    }

    xTimerStart(s_timer, 0);

    ESP_LOGI(TAG, "UART%d init OK, TX:GPIO%d RX:GPIO%d baud:%d interval:%dms",
             CONFIG_UART_COMM_PORT_NUM,
             CONFIG_UART_COMM_TX_GPIO,
             CONFIG_UART_COMM_RX_GPIO,
             CONFIG_UART_COMM_BAUD_RATE,
             CONFIG_UART_COMM_INTERVAL_MS);

    return ESP_OK;
}

esp_err_t uart_comm_deinit(void)
{
    if (s_timer) {
        xTimerStop(s_timer, portMAX_DELAY);
        xTimerDelete(s_timer, portMAX_DELAY);
        s_timer = NULL;
    }
    uart_driver_delete(CONFIG_UART_COMM_PORT_NUM);
    return ESP_OK;
}
