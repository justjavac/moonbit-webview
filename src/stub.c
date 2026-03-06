#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "moonbit.h"

typedef void *webview_t;

typedef void (*moonbit_webview_bind_callback_t)(void *seq, void *req, void *arg);

struct moonbit_webview_binding {
  moonbit_webview_bind_callback_t callback;
  void *arg;
};

int webview_bind(
  webview_t w,
  const char *name,
  void (*fn)(const char *seq, const char *req, void *arg),
  void *arg
);
int webview_unbind(webview_t w, const char *name);

static void moonbit_webview_free_binding(struct moonbit_webview_binding *binding) {
  if (binding == NULL) {
    return;
  }
  if (binding->arg != NULL) {
    moonbit_decref(binding->arg);
  }
  free(binding);
}

static void moonbit_webview_bind_trampoline(
  const char *seq,
  const char *req,
  void *arg
) {
  struct moonbit_webview_binding *binding = arg;
  binding->callback((void *)seq, (void *)req, binding->arg);
}

void *moonbit_webview_bind(
  webview_t w,
  const char *name,
  moonbit_webview_bind_callback_t fn,
  void *arg
) {
  struct moonbit_webview_binding *binding =
    (struct moonbit_webview_binding *)malloc(sizeof(struct moonbit_webview_binding));
  int result;

  if (binding == NULL) {
    return NULL;
  }

  binding->callback = fn;
  binding->arg = arg;
  result = webview_bind(w, name, moonbit_webview_bind_trampoline, binding);
  if (result != 0) {
    moonbit_webview_free_binding(binding);
    return NULL;
  }

  return binding;
}

int moonbit_webview_unbind(webview_t w, const char *name, void *raw_binding) {
  struct moonbit_webview_binding *binding = raw_binding;
  int result = webview_unbind(w, name);
  moonbit_webview_free_binding(binding);
  return result;
}

moonbit_bytes_t moonbit_webview_copy_cstr(void *raw_cstr) {
  const char *cstr = raw_cstr;
  moonbit_bytes_t bytes;
  size_t len;

  if (cstr == NULL) {
    bytes = moonbit_make_bytes_raw(1);
    bytes[0] = '\0';
    return bytes;
  }

  len = strlen(cstr) + 1;
  bytes = moonbit_make_bytes_raw((int32_t)len);
  memcpy(bytes, cstr, len);
  return bytes;
}
