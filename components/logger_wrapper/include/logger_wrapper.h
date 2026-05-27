#pragma once

#include "esp_log.h"
#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint32_t        timestamp_ms;
    esp_log_level_t level;
    const char     *tag;
    const char     *message;
} logger_wrapper_entry_t;

typedef bool (*logger_wrapper_dump_cb_t)(const logger_wrapper_entry_t *entry, void *user_ctx);

esp_err_t logger_wrapper_init(void);
void      logger_wrapper_deinit(void);
uint32_t  logger_wrapper_get_count(void);
esp_err_t logger_wrapper_dump(logger_wrapper_dump_cb_t callback, void *user_ctx);
void      logger_wrapper_clear(void);

void _logger_wrapper_log(esp_log_level_t level, const char *tag,
                         const char *format, ...) __attribute__((format(printf, 3, 4)));

#ifdef __cplusplus
}
#endif

#undef ESP_LOGE
#undef ESP_LOGW
#undef ESP_LOGI
#undef ESP_LOGD
#undef ESP_LOGV

#define ESP_LOGE(tag, format, ...) do { \
    if (ESP_LOG_ENABLED(ESP_LOG_ERROR)) { \
        _logger_wrapper_log(ESP_LOG_ERROR, tag, format, ##__VA_ARGS__); \
        ESP_LOG_LEVEL(ESP_LOG_ERROR, tag, format, ##__VA_ARGS__); \
    } \
} while(0)

#define ESP_LOGW(tag, format, ...) do { \
    if (ESP_LOG_ENABLED(ESP_LOG_WARN)) { \
        _logger_wrapper_log(ESP_LOG_WARN, tag, format, ##__VA_ARGS__); \
        ESP_LOG_LEVEL(ESP_LOG_WARN, tag, format, ##__VA_ARGS__); \
    } \
} while(0)

#define ESP_LOGI(tag, format, ...) do { \
    if (ESP_LOG_ENABLED(ESP_LOG_INFO)) { \
        _logger_wrapper_log(ESP_LOG_INFO, tag, format, ##__VA_ARGS__); \
        ESP_LOG_LEVEL(ESP_LOG_INFO, tag, format, ##__VA_ARGS__); \
    } \
} while(0)

#define ESP_LOGD(tag, format, ...) do { \
    if (ESP_LOG_ENABLED(ESP_LOG_DEBUG)) { \
        _logger_wrapper_log(ESP_LOG_DEBUG, tag, format, ##__VA_ARGS__); \
        ESP_LOG_LEVEL(ESP_LOG_DEBUG, tag, format, ##__VA_ARGS__); \
    } \
} while(0)

#define ESP_LOGV(tag, format, ...) do { \
    if (ESP_LOG_ENABLED(ESP_LOG_VERBOSE)) { \
        _logger_wrapper_log(ESP_LOG_VERBOSE, tag, format, ##__VA_ARGS__); \
        ESP_LOG_LEVEL(ESP_LOG_VERBOSE, tag, format, ##__VA_ARGS__); \
    } \
} while(0)
