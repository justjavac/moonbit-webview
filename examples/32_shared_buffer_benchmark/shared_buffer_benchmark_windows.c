#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "moonbit.h"

#ifdef _WIN32
#define CINTERFACE
#define COBJMACROS
#include <windows.h>
#include <ole2.h>
#include <wchar.h>
#include "../../build/_deps/microsoft_web_webview2-src/build/native/include/WebView2.h"
#ifdef _MSC_VER
#pragma comment(lib, "ole32.lib")
#endif

/*
 * The vendored WebView2 header currently stops before SharedBuffer. Keep the
 * newer COM ABI local to this prototype instead of making it part of lepus yet.
 */
#define LEPUS_WEBVIEW2_17_POST_SHARED_BUFFER_TO_SCRIPT_INDEX 116
#define LEPUS_ENVIRONMENT12_CREATE_SHARED_BUFFER_INDEX 24
#define LEPUS_SHARED_BUFFER_GET_BUFFER_INDEX 4
#define LEPUS_SHARED_BUFFER_CLOSE_INDEX 7
#define LEPUS_UNKNOWN_RELEASE_INDEX 2
#define LEPUS_MAX_SHARED_BUFFER_SIZE (64 * 1024 * 1024)
#define LEPUS_SHARED_BUFFER_ACCESS_READ_ONLY 0
#define LEPUS_SHARED_BUFFER_ACCESS_READ_WRITE 1
#define LEPUS_SUM_BUFFER_SIZE 64
#define LEPUS_SUM_X_OFFSET 0
#define LEPUS_SUM_Y_OFFSET 4
#define LEPUS_SUM_RESULT_OFFSET 8

static const IID LEPUS_IID_ICoreWebView2_17 = {
    0x702e75d4,
    0xfd44,
    0x434d,
    {0x9d, 0x70, 0x1a, 0x68, 0xa6, 0xb1, 0x19, 0x2a}};

static const IID LEPUS_IID_ICoreWebView2Environment12 = {
    0xf503db9b,
    0x739f,
    0x48dd,
    {0xb1, 0x51, 0xfd, 0xfc, 0xf2, 0x53, 0xf5, 0x4e}};

typedef ULONG(STDMETHODCALLTYPE *lepus_release_fn)(void *self);
typedef HRESULT(STDMETHODCALLTYPE *lepus_create_shared_buffer_fn)(
    void *self, UINT64 size, void **shared_buffer);
typedef HRESULT(STDMETHODCALLTYPE *lepus_shared_buffer_get_buffer_fn)(
    void *self, BYTE **buffer);
typedef HRESULT(STDMETHODCALLTYPE *lepus_shared_buffer_close_fn)(void *self);
typedef HRESULT(STDMETHODCALLTYPE *lepus_post_shared_buffer_to_script_fn)(
    void *self, void *shared_buffer, int access, LPCWSTR additional_data_as_json);

static char lepus_example_shared_buffer_error[512] = "ok";

typedef struct {
  int64_t controller_handle;
  void *webview17;
  void *environment12;
  void *shared_buffer;
  BYTE *buffer;
  uint64_t capacity;
  void *sum_shared_buffer;
  BYTE *sum_buffer;
  uint64_t sum_capacity;
} lepus_example_shared_buffer_cache_t;

static lepus_example_shared_buffer_cache_t lepus_example_shared_buffer_cache = {
    0, NULL, NULL, NULL, NULL, 0, NULL, NULL, 0};

static void lepus_example_set_ok(void) {
  snprintf(lepus_example_shared_buffer_error,
           sizeof(lepus_example_shared_buffer_error), "ok");
}

static HRESULT lepus_example_set_hresult(const char *step, HRESULT hr) {
  snprintf(lepus_example_shared_buffer_error,
           sizeof(lepus_example_shared_buffer_error),
           "%s failed: HRESULT 0x%08lx",
           step,
           (unsigned long)(uint32_t)hr);
  return hr;
}

static HRESULT lepus_example_set_message(const char *message, HRESULT hr) {
  snprintf(lepus_example_shared_buffer_error,
           sizeof(lepus_example_shared_buffer_error),
           "%s",
           message);
  return hr;
}

static void **lepus_example_vtbl(void *interface_pointer) {
  return *(void ***)interface_pointer;
}

static void lepus_example_release_unknown(void *interface_pointer) {
  if (interface_pointer == NULL) {
    return;
  }
  void **vtbl = lepus_example_vtbl(interface_pointer);
  lepus_release_fn release = (lepus_release_fn)vtbl[LEPUS_UNKNOWN_RELEASE_INDEX];
  release(interface_pointer);
}

static HRESULT lepus_example_close_shared_buffer(void *shared_buffer) {
  if (shared_buffer == NULL) {
    return S_OK;
  }
  void **vtbl = lepus_example_vtbl(shared_buffer);
  lepus_shared_buffer_close_fn close =
      (lepus_shared_buffer_close_fn)vtbl[LEPUS_SHARED_BUFFER_CLOSE_INDEX];
  return close(shared_buffer);
}

static void lepus_example_release_shared_buffer(void *shared_buffer) {
  if (shared_buffer == NULL) {
    return;
  }
  (void)lepus_example_close_shared_buffer(shared_buffer);
  lepus_example_release_unknown(shared_buffer);
}

static void lepus_example_release_cached_shared_buffer(void) {
  lepus_example_release_shared_buffer(lepus_example_shared_buffer_cache.shared_buffer);
  lepus_example_shared_buffer_cache.shared_buffer = NULL;
  lepus_example_shared_buffer_cache.buffer = NULL;
  lepus_example_shared_buffer_cache.capacity = 0;
}

static void lepus_example_release_cached_sum_buffer(void) {
  lepus_example_release_shared_buffer(
      lepus_example_shared_buffer_cache.sum_shared_buffer);
  lepus_example_shared_buffer_cache.sum_shared_buffer = NULL;
  lepus_example_shared_buffer_cache.sum_buffer = NULL;
  lepus_example_shared_buffer_cache.sum_capacity = 0;
}

static void lepus_example_release_cache(void) {
  lepus_example_release_cached_shared_buffer();
  lepus_example_release_cached_sum_buffer();
  lepus_example_release_unknown(lepus_example_shared_buffer_cache.environment12);
  lepus_example_release_unknown(lepus_example_shared_buffer_cache.webview17);
  lepus_example_shared_buffer_cache.controller_handle = 0;
  lepus_example_shared_buffer_cache.webview17 = NULL;
  lepus_example_shared_buffer_cache.environment12 = NULL;
}

static HRESULT lepus_example_create_shared_buffer(
    void *environment12, uint64_t size, void **shared_buffer) {
  void **vtbl = lepus_example_vtbl(environment12);
  lepus_create_shared_buffer_fn create_shared_buffer =
      (lepus_create_shared_buffer_fn)
          vtbl[LEPUS_ENVIRONMENT12_CREATE_SHARED_BUFFER_INDEX];
  return create_shared_buffer(environment12, (UINT64)size, shared_buffer);
}

static HRESULT lepus_example_get_shared_buffer_bytes(
    void *shared_buffer, BYTE **buffer) {
  void **vtbl = lepus_example_vtbl(shared_buffer);
  lepus_shared_buffer_get_buffer_fn get_buffer =
      (lepus_shared_buffer_get_buffer_fn)
          vtbl[LEPUS_SHARED_BUFFER_GET_BUFFER_INDEX];
  return get_buffer(shared_buffer, buffer);
}

static HRESULT lepus_example_post_shared_buffer(
    void *webview17,
    void *shared_buffer,
    int access,
    LPCWSTR additional_data_as_json) {
  void **vtbl = lepus_example_vtbl(webview17);
  lepus_post_shared_buffer_to_script_fn post_shared_buffer =
      (lepus_post_shared_buffer_to_script_fn)
          vtbl[LEPUS_WEBVIEW2_17_POST_SHARED_BUFFER_TO_SCRIPT_INDEX];
  return post_shared_buffer(
      webview17, shared_buffer, access, additional_data_as_json);
}

static HRESULT lepus_example_get_core_webview(
    int64_t controller_handle, ICoreWebView2 **webview) {
  ICoreWebView2Controller *controller =
      (ICoreWebView2Controller *)(uintptr_t)controller_handle;
  if (controller == NULL) {
    return lepus_example_set_message("Native controller handle is null", E_POINTER);
  }
  HRESULT hr = ICoreWebView2Controller_get_CoreWebView2(controller, webview);
  if (FAILED(hr)) {
    return lepus_example_set_hresult("ICoreWebView2Controller::get_CoreWebView2", hr);
  }
  return S_OK;
}

static HRESULT lepus_example_get_shared_buffer_interfaces(
    int64_t controller_handle, void **webview17, void **environment12) {
  ICoreWebView2 *webview = NULL;
  ICoreWebView2_3 *webview3 = NULL;
  ICoreWebView2Environment *environment = NULL;
  HRESULT hr = lepus_example_get_core_webview(controller_handle, &webview);
  if (FAILED(hr)) {
    return hr;
  }
  hr = ICoreWebView2_QueryInterface(
      webview, &LEPUS_IID_ICoreWebView2_17, webview17);
  if (FAILED(hr)) {
    lepus_example_set_hresult("QueryInterface(ICoreWebView2_17)", hr);
    goto cleanup;
  }
  hr = ICoreWebView2_QueryInterface(
      webview, &IID_ICoreWebView2_3, (void **)&webview3);
  if (FAILED(hr)) {
    lepus_example_set_hresult("QueryInterface(ICoreWebView2_3)", hr);
    goto cleanup;
  }
  hr = ICoreWebView2_3_get_Environment(webview3, &environment);
  if (FAILED(hr)) {
    lepus_example_set_hresult("ICoreWebView2_3::get_Environment", hr);
    goto cleanup;
  }
  hr = ICoreWebView2Environment_QueryInterface(
      environment, &LEPUS_IID_ICoreWebView2Environment12, environment12);
  if (FAILED(hr)) {
    lepus_example_set_hresult(
        "QueryInterface(ICoreWebView2Environment12)", hr);
    goto cleanup;
  }

cleanup:
  if (FAILED(hr)) {
    lepus_example_release_unknown(*webview17);
    lepus_example_release_unknown(*environment12);
    *webview17 = NULL;
    *environment12 = NULL;
  }
  if (environment != NULL) {
    ICoreWebView2Environment_Release(environment);
  }
  if (webview3 != NULL) {
    ICoreWebView2_3_Release(webview3);
  }
  if (webview != NULL) {
    ICoreWebView2_Release(webview);
  }
  return hr;
}

static HRESULT lepus_example_ensure_shared_buffer_interfaces(
    int64_t controller_handle) {
  HRESULT hr;
  if (lepus_example_shared_buffer_cache.controller_handle == controller_handle &&
      lepus_example_shared_buffer_cache.webview17 != NULL &&
      lepus_example_shared_buffer_cache.environment12 != NULL) {
    return S_OK;
  }
  lepus_example_release_cache();
  hr = lepus_example_get_shared_buffer_interfaces(
      controller_handle,
      &lepus_example_shared_buffer_cache.webview17,
      &lepus_example_shared_buffer_cache.environment12);
  if (FAILED(hr)) {
    lepus_example_release_cache();
    return hr;
  }
  lepus_example_shared_buffer_cache.controller_handle = controller_handle;
  return S_OK;
}

static HRESULT lepus_example_ensure_shared_buffer_capacity(uint64_t size) {
  HRESULT hr;
  void *shared_buffer = NULL;
  BYTE *buffer = NULL;
  if (lepus_example_shared_buffer_cache.shared_buffer != NULL &&
      lepus_example_shared_buffer_cache.capacity >= size &&
      lepus_example_shared_buffer_cache.buffer != NULL) {
    return S_OK;
  }
  lepus_example_release_cached_shared_buffer();
  hr = lepus_example_create_shared_buffer(
      lepus_example_shared_buffer_cache.environment12, size, &shared_buffer);
  if (FAILED(hr)) {
    return lepus_example_set_hresult(
        "ICoreWebView2Environment12::CreateSharedBuffer", hr);
  }
  hr = lepus_example_get_shared_buffer_bytes(shared_buffer, &buffer);
  if (FAILED(hr)) {
    lepus_example_release_shared_buffer(shared_buffer);
    return lepus_example_set_hresult("ICoreWebView2SharedBuffer::get_Buffer", hr);
  }
  lepus_example_shared_buffer_cache.shared_buffer = shared_buffer;
  lepus_example_shared_buffer_cache.buffer = buffer;
  lepus_example_shared_buffer_cache.capacity = size;
  return S_OK;
}

static HRESULT lepus_example_ensure_sum_buffer(void) {
  HRESULT hr;
  void *shared_buffer = NULL;
  BYTE *buffer = NULL;
  if (lepus_example_shared_buffer_cache.sum_shared_buffer != NULL &&
      lepus_example_shared_buffer_cache.sum_buffer != NULL &&
      lepus_example_shared_buffer_cache.sum_capacity >= LEPUS_SUM_BUFFER_SIZE) {
    return S_OK;
  }
  lepus_example_release_cached_sum_buffer();
  hr = lepus_example_create_shared_buffer(
      lepus_example_shared_buffer_cache.environment12,
      LEPUS_SUM_BUFFER_SIZE,
      &shared_buffer);
  if (FAILED(hr)) {
    return lepus_example_set_hresult(
        "ICoreWebView2Environment12::CreateSharedBuffer(sum)", hr);
  }
  hr = lepus_example_get_shared_buffer_bytes(shared_buffer, &buffer);
  if (FAILED(hr)) {
    lepus_example_release_shared_buffer(shared_buffer);
    return lepus_example_set_hresult(
        "ICoreWebView2SharedBuffer::get_Buffer(sum)", hr);
  }
  memset(buffer, 0, LEPUS_SUM_BUFFER_SIZE);
  lepus_example_shared_buffer_cache.sum_shared_buffer = shared_buffer;
  lepus_example_shared_buffer_cache.sum_buffer = buffer;
  lepus_example_shared_buffer_cache.sum_capacity = LEPUS_SUM_BUFFER_SIZE;
  return S_OK;
}

static int32_t lepus_example_load_i32(const BYTE *buffer, size_t offset) {
  int32_t value = 0;
  memcpy(&value, buffer + offset, sizeof(value));
  return value;
}

static void lepus_example_store_i32(BYTE *buffer, size_t offset, int32_t value) {
  memcpy(buffer + offset, &value, sizeof(value));
}

static BYTE *lepus_example_get_sum_buffer_or_error(void) {
  BYTE *buffer = lepus_example_shared_buffer_cache.sum_buffer;
  if (buffer == NULL ||
      lepus_example_shared_buffer_cache.sum_capacity < LEPUS_SUM_BUFFER_SIZE) {
    lepus_example_set_message(
        "Shared sum buffer has not been prepared", E_POINTER);
    return NULL;
  }
  return buffer;
}
#endif

MOONBIT_FFI_EXPORT int32_t lepus_example_shared_buffer_probe(
    int64_t controller_handle) {
#ifdef _WIN32
  int32_t mask = 1;
  ICoreWebView2 *webview = NULL;
  ICoreWebView2_3 *webview3 = NULL;
  ICoreWebView2Environment *environment = NULL;
  void *webview17 = NULL;
  void *environment12 = NULL;
  void *shared_buffer = NULL;
  HRESULT hr;

  lepus_example_set_ok();
  if (controller_handle == 0) {
    lepus_example_set_message("Native controller handle is null", E_POINTER);
    return mask;
  }
  mask |= 2;
  hr = lepus_example_get_core_webview(controller_handle, &webview);
  if (FAILED(hr)) {
    return mask;
  }
  mask |= 4;
  hr = ICoreWebView2_QueryInterface(
      webview, &LEPUS_IID_ICoreWebView2_17, &webview17);
  if (SUCCEEDED(hr)) {
    mask |= 8;
  } else {
    lepus_example_set_hresult("QueryInterface(ICoreWebView2_17)", hr);
  }
  hr = ICoreWebView2_QueryInterface(
      webview, &IID_ICoreWebView2_3, (void **)&webview3);
  if (SUCCEEDED(hr)) {
    hr = ICoreWebView2_3_get_Environment(webview3, &environment);
  }
  if (SUCCEEDED(hr)) {
    hr = ICoreWebView2Environment_QueryInterface(
        environment, &LEPUS_IID_ICoreWebView2Environment12, &environment12);
    if (SUCCEEDED(hr)) {
      mask |= 16;
      hr = lepus_example_create_shared_buffer(environment12, 16, &shared_buffer);
      if (SUCCEEDED(hr)) {
        mask |= 32;
      } else {
        lepus_example_set_hresult(
            "ICoreWebView2Environment12::CreateSharedBuffer", hr);
      }
    } else {
      lepus_example_set_hresult(
          "QueryInterface(ICoreWebView2Environment12)", hr);
    }
  } else {
    lepus_example_set_hresult("ICoreWebView2_3::get_Environment", hr);
  }
  if ((mask & (8 | 16 | 32)) == (8 | 16 | 32)) {
    lepus_example_set_ok();
  }
  lepus_example_release_shared_buffer(shared_buffer);
  lepus_example_release_unknown(environment12);
  if (environment != NULL) {
    ICoreWebView2Environment_Release(environment);
  }
  if (webview3 != NULL) {
    ICoreWebView2_3_Release(webview3);
  }
  lepus_example_release_unknown(webview17);
  if (webview != NULL) {
    ICoreWebView2_Release(webview);
  }
  return mask;
#else
  (void)controller_handle;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t lepus_example_shared_buffer_publish_bytes(
    int64_t controller_handle,
    moonbit_bytes_t payload,
    int32_t size,
    int32_t sequence,
    int32_t checksum) {
#ifdef _WIN32
  wchar_t additional_data[256];
  HRESULT hr;
  int written;

  lepus_example_set_ok();
  if (payload == NULL) {
    return (int32_t)lepus_example_set_message(
        "SharedBuffer payload is null", E_POINTER);
  }
  if (size <= 0 || size > LEPUS_MAX_SHARED_BUFFER_SIZE) {
    return (int32_t)lepus_example_set_message(
        "SharedBuffer size is outside the prototype limit", E_INVALIDARG);
  }
  hr = lepus_example_ensure_shared_buffer_interfaces(controller_handle);
  if (FAILED(hr)) {
    return (int32_t)hr;
  }
  hr = lepus_example_ensure_shared_buffer_capacity((uint64_t)(uint32_t)size);
  if (FAILED(hr)) {
    return (int32_t)hr;
  }
  memcpy(
      lepus_example_shared_buffer_cache.buffer,
      payload,
      (size_t)(uint32_t)size);
  written = swprintf(
      additional_data,
      sizeof(additional_data) / sizeof(additional_data[0]),
      L"{\"kind\":\"lepus-shared-buffer\",\"sequence\":%d,"
      L"\"size\":%d,\"capacity\":%llu,\"checksum\":%lu}",
      sequence,
      size,
      (unsigned long long)lepus_example_shared_buffer_cache.capacity,
      (unsigned long)(uint32_t)checksum);
  if (written < 0 ||
      written >= (int)(sizeof(additional_data) / sizeof(additional_data[0]))) {
    return (int32_t)lepus_example_set_message(
        "SharedBuffer additional data did not fit in the fixed buffer",
        E_OUTOFMEMORY);
  }
  hr = lepus_example_post_shared_buffer(
      lepus_example_shared_buffer_cache.webview17,
      lepus_example_shared_buffer_cache.shared_buffer,
      LEPUS_SHARED_BUFFER_ACCESS_READ_ONLY,
      additional_data);
  if (FAILED(hr)) {
    return (int32_t)lepus_example_set_hresult(
        "ICoreWebView2_17::PostSharedBufferToScript", hr);
  }
  lepus_example_set_ok();
  return 0;
#else
  (void)controller_handle;
  (void)payload;
  (void)size;
  (void)sequence;
  (void)checksum;
  return -1;
#endif
}

MOONBIT_FFI_EXPORT int32_t lepus_example_shared_sum_prepare(
    int64_t controller_handle) {
#ifdef _WIN32
  wchar_t additional_data[160];
  HRESULT hr;
  int written;

  lepus_example_set_ok();
  hr = lepus_example_ensure_shared_buffer_interfaces(controller_handle);
  if (FAILED(hr)) {
    return (int32_t)hr;
  }
  hr = lepus_example_ensure_sum_buffer();
  if (FAILED(hr)) {
    return (int32_t)hr;
  }
  written = swprintf(
      additional_data,
      sizeof(additional_data) / sizeof(additional_data[0]),
      L"{\"kind\":\"lepus-sum-buffer\",\"size\":%d}",
      LEPUS_SUM_BUFFER_SIZE);
  if (written < 0 ||
      written >= (int)(sizeof(additional_data) / sizeof(additional_data[0]))) {
    return (int32_t)lepus_example_set_message(
        "Shared sum additional data did not fit in the fixed buffer",
        E_OUTOFMEMORY);
  }
  hr = lepus_example_post_shared_buffer(
      lepus_example_shared_buffer_cache.webview17,
      lepus_example_shared_buffer_cache.sum_shared_buffer,
      LEPUS_SHARED_BUFFER_ACCESS_READ_WRITE,
      additional_data);
  if (FAILED(hr)) {
    return (int32_t)lepus_example_set_hresult(
        "ICoreWebView2_17::PostSharedBufferToScript(sum)", hr);
  }
  lepus_example_set_ok();
  return 0;
#else
  (void)controller_handle;
  return -1;
#endif
}

MOONBIT_FFI_EXPORT int32_t lepus_example_shared_sum_read_x(void) {
#ifdef _WIN32
  lepus_example_set_ok();
  BYTE *buffer = lepus_example_get_sum_buffer_or_error();
  if (buffer == NULL) {
    return 0;
  }
  MemoryBarrier();
  return lepus_example_load_i32(buffer, LEPUS_SUM_X_OFFSET);
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t lepus_example_shared_sum_read_y(void) {
#ifdef _WIN32
  lepus_example_set_ok();
  BYTE *buffer = lepus_example_get_sum_buffer_or_error();
  if (buffer == NULL) {
    return 0;
  }
  MemoryBarrier();
  return lepus_example_load_i32(buffer, LEPUS_SUM_Y_OFFSET);
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t lepus_example_shared_sum_write_result(
    int32_t result) {
#ifdef _WIN32
  lepus_example_set_ok();
  BYTE *buffer = lepus_example_get_sum_buffer_or_error();
  if (buffer == NULL) {
    return (int32_t)E_POINTER;
  }
  lepus_example_store_i32(buffer, LEPUS_SUM_RESULT_OFFSET, result);
  MemoryBarrier();
  return 0;
#else
  (void)result;
  return -1;
#endif
}

MOONBIT_FFI_EXPORT void lepus_example_shared_buffer_release_last(void) {
#ifdef _WIN32
  lepus_example_release_cache();
  lepus_example_set_ok();
#endif
}

MOONBIT_FFI_EXPORT moonbit_bytes_t lepus_example_shared_buffer_last_error(void) {
  const char *message =
#ifdef _WIN32
      lepus_example_shared_buffer_error;
#else
      "SharedBuffer prototype is Windows/WebView2-only";
#endif
  size_t len = strlen(message) + 1;
  moonbit_bytes_t bytes = moonbit_make_bytes_raw((int32_t)len);
  memcpy(bytes, message, len);
  return bytes;
}
