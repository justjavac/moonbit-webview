#include "webview/webview.h"

webview_t moonbit_webview_create(int debug, void *window) {
  return webview_create(debug, window);
}

void moonbit_webview_destroy(webview_t w) {
  webview_destroy(w);
}

// void webview_run(webview_t w);
void moonbit_webview_run(webview_t w) {
  webview_run(w);
}

// void webview_terminate(webview_t w);
void moonbit_webview_terminate(webview_t w) {
  webview_terminate(w);
}

// void webview_dispatch(webview_t w, void (*fn)(webview_t w, void *arg), void *arg);
void moonbit_webview_dispatch(webview_t w, void (*fn)(webview_t w, void *arg), void *arg) {
  webview_dispatch(w, fn, arg);
}

// void *webview_get_window(webview_t w);
void *moonbit_webview_get_window(webview_t w) {
  return webview_get_window(w);
}

// void *webview_get_native_handle(webview_t w, webview_native_handle_kind_t kind);
void *moonbit_webview_get_native_handle(webview_t w, webview_native_handle_kind_t kind) {
  return webview_get_native_handle(w, kind);
}

// void webview_set_title(webview_t w, const char *title);
void moonbit_webview_set_title(webview_t w, const char *title) {
  webview_set_title(w, title);
}

// void webview_set_size(webview_t w, int width, int height, webview_hint_t hints);
void moonbit_webview_set_size(webview_t w, int width, int height, webview_hint_t hints) {
  webview_set_size(w, width, height, hints);
}

// void webview_navigate(webview_t w, const char *url);
void moonbit_webview_navigate(webview_t w, const char *url) {
  webview_navigate(w, url);
}

// void webview_set_html(webview_t w, const char *html);
void moonbit_webview_set_html(webview_t w, const char *html) {
  webview_set_html(w, html);
}

// void webview_init(webview_t w, const char *js);
void moonbit_webview_init(webview_t w, const char *js) {
  webview_init(w, js);
}

// void webview_eval(webview_t w, const char *js);
void moonbit_webview_eval(webview_t w, const char *js) {
  webview_eval(w, js);
}

// void webview_bind(webview_t w, const char *name, void (*fn)(const char *seq, const char *req, void *arg), void *arg);
void moonbit_webview_bind(webview_t w, const char *name, void (*fn)(const char *seq, const char *req, void *arg), void *arg) {
  webview_bind(w, name, fn, arg);
}

// void webview_unbind(webview_t w, const char *name);
void moonbit_webview_unbind(webview_t w, const char *name) {
  webview_unbind(w, name);
}

// void webview_return(webview_t w, const char *seq, int status, const char *result);
void moonbit_webview_return(webview_t w, const char *seq, int status, const char *result) {
  webview_return(w, seq, status, result);
}