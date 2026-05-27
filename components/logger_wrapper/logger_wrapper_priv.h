#pragma once

#include <stdint.h>
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "esp_log.h"
#include "logger_wrapper.h"
#include "sdkconfig.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint32_t timestamp_ms;
    uint8_t  level;
    uint8_t  tag_len;
    uint16_t msg_len;
} __attribute__((packed)) entry_header_t;

typedef struct {
    uint8_t          *buffer;
    uint32_t          buffer_size;
    uint32_t          entry_size;
    uint32_t          max_entries;
    volatile uint32_t head;
    volatile uint32_t count;
    bool              wrapped;
    SemaphoreHandle_t mutex;
    bool              initialized;
} ring_buffer_t;

#define RB_ENTRY_SIZE \
    (sizeof(entry_header_t) + CONFIG_LOGGER_WRAPPER_MAX_TAG_LEN + CONFIG_LOGGER_WRAPPER_MAX_MSG_LEN)

#define RB_MAX_ENTRIES (CONFIG_LOGGER_WRAPPER_RING_BUFFER_SIZE / RB_ENTRY_SIZE)

bool     rb_init(ring_buffer_t *rb);
void     rb_deinit(ring_buffer_t *rb);
bool     rb_store(ring_buffer_t *rb, uint32_t ts, esp_log_level_t level,
                  const char *tag, const char *msg);
uint32_t rb_count(const ring_buffer_t *rb);
void     rb_clear(ring_buffer_t *rb);
bool     rb_dump(const ring_buffer_t *rb, logger_wrapper_dump_cb_t cb, void *ctx);

#ifdef __cplusplus
}
#endif
