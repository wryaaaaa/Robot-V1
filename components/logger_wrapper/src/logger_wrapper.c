#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "logger_wrapper_priv.h"
#include "esp_heap_caps.h"

static ring_buffer_t s_rb;

bool rb_init(ring_buffer_t *rb)
{
    rb->entry_size  = RB_ENTRY_SIZE;
    rb->max_entries = RB_MAX_ENTRIES;
    rb->buffer_size = rb->entry_size * rb->max_entries;
    rb->head    = 0;
    rb->count   = 0;
    rb->wrapped = false;

    if (rb->max_entries == 0) {
        rb->initialized = false;
        return false;
    }

    rb->buffer = (uint8_t *)heap_caps_malloc(rb->buffer_size,
                                              MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (rb->buffer == NULL) {
        rb->initialized = false;
        return false;
    }

    rb->mutex = xSemaphoreCreateMutex();
    if (rb->mutex == NULL) {
        heap_caps_free(rb->buffer);
        rb->buffer = NULL;
        rb->initialized = false;
        return false;
    }

    rb->initialized = true;
    return true;
}

void rb_deinit(ring_buffer_t *rb)
{
    if (rb->mutex) {
        xSemaphoreTake(rb->mutex, portMAX_DELAY);
        rb->initialized = false;
        if (rb->buffer) {
            heap_caps_free(rb->buffer);
            rb->buffer = NULL;
        }
        xSemaphoreGive(rb->mutex);
        vSemaphoreDelete(rb->mutex);
        rb->mutex = NULL;
    } else {
        rb->initialized = false;
        if (rb->buffer) {
            heap_caps_free(rb->buffer);
            rb->buffer = NULL;
        }
    }
}

bool rb_store(ring_buffer_t *rb, uint32_t ts, esp_log_level_t level,
              const char *tag, const char *msg)
{
    if (!rb->initialized) {
        return false;
    }

    xSemaphoreTake(rb->mutex, portMAX_DELAY);

    uint8_t *slot = rb->buffer + (rb->head * rb->entry_size);
    entry_header_t *hdr = (entry_header_t *)slot;
    char *tag_buf = (char *)(slot + sizeof(entry_header_t));
    char *msg_buf = tag_buf + CONFIG_LOGGER_WRAPPER_MAX_TAG_LEN;

    size_t tag_len = strlen(tag);
    size_t msg_len = strlen(msg);

    if (tag_len >= CONFIG_LOGGER_WRAPPER_MAX_TAG_LEN) {
        tag_len = CONFIG_LOGGER_WRAPPER_MAX_TAG_LEN - 1;
    }
    if (msg_len >= CONFIG_LOGGER_WRAPPER_MAX_MSG_LEN) {
        msg_len = CONFIG_LOGGER_WRAPPER_MAX_MSG_LEN - 1;
    }

    hdr->timestamp_ms = ts;
    hdr->level        = (uint8_t)level;
    hdr->tag_len      = (uint8_t)tag_len;
    hdr->msg_len      = (uint16_t)msg_len;

    memcpy(tag_buf, tag, tag_len);
    tag_buf[tag_len] = '\0';
    memcpy(msg_buf, msg, msg_len);
    msg_buf[msg_len] = '\0';

    rb->head = (rb->head + 1) % rb->max_entries;
    if (rb->count < rb->max_entries) {
        rb->count++;
    } else {
        rb->wrapped = true;
    }

    xSemaphoreGive(rb->mutex);
    return true;
}

uint32_t rb_count(const ring_buffer_t *rb)
{
    if (!rb->initialized) {
        return 0;
    }
    return rb->count;
}

void rb_clear(ring_buffer_t *rb)
{
    if (!rb->initialized) {
        return;
    }
    xSemaphoreTake(rb->mutex, portMAX_DELAY);
    rb->head    = 0;
    rb->count   = 0;
    rb->wrapped = false;
    xSemaphoreGive(rb->mutex);
}

bool rb_dump(const ring_buffer_t *rb, logger_wrapper_dump_cb_t cb, void *ctx)
{
    if (!rb->initialized || cb == NULL) {
        return false;
    }

    xSemaphoreTake(rb->mutex, portMAX_DELAY);

    if (rb->count == 0) {
        xSemaphoreGive(rb->mutex);
        return true;
    }

    uint32_t start;
    if (rb->wrapped) {
        start = rb->head;
    } else {
        start = 0;
    }

    for (uint32_t i = 0; i < rb->count; i++) {
        uint32_t idx = (start + i) % rb->max_entries;
        uint8_t *slot = rb->buffer + (idx * rb->entry_size);
        entry_header_t *hdr = (entry_header_t *)slot;

        logger_wrapper_entry_t entry;
        entry.timestamp_ms = hdr->timestamp_ms;
        entry.level        = (esp_log_level_t)hdr->level;
        entry.tag          = (const char *)(slot + sizeof(entry_header_t));
        entry.message      = (const char *)(slot + sizeof(entry_header_t)
                                            + CONFIG_LOGGER_WRAPPER_MAX_TAG_LEN);

        xSemaphoreGive(rb->mutex);

        bool cont = cb(&entry, ctx);

        xSemaphoreTake(rb->mutex, portMAX_DELAY);

        if (!cont) {
            xSemaphoreGive(rb->mutex);
            return true;
        }
    }

    xSemaphoreGive(rb->mutex);
    return true;
}

/* --- Public API --- */

esp_err_t logger_wrapper_init(void)
{
    if (rb_init(&s_rb)) {
        return ESP_OK;
    }
    return ESP_ERR_NO_MEM;
}

void logger_wrapper_deinit(void)
{
    rb_deinit(&s_rb);
}

uint32_t logger_wrapper_get_count(void)
{
    return rb_count(&s_rb);
}

esp_err_t logger_wrapper_dump(logger_wrapper_dump_cb_t callback, void *user_ctx)
{
    if (callback == NULL) {
        return ESP_ERR_INVALID_ARG;
    }
    if (rb_dump(&s_rb, callback, user_ctx)) {
        return ESP_OK;
    }
    return ESP_FAIL;
}

void logger_wrapper_clear(void)
{
    rb_clear(&s_rb);
}

void _logger_wrapper_log(esp_log_level_t level, const char *tag,
                         const char *format, ...)
{
    if (!s_rb.initialized) {
        return;
    }

    uint32_t ts = esp_log_timestamp();

    char msg[CONFIG_LOGGER_WRAPPER_MAX_MSG_LEN];
    va_list args;
    va_start(args, format);
    vsnprintf(msg, sizeof(msg), format, args);
    va_end(args);

    rb_store(&s_rb, ts, level, tag, msg);
}
