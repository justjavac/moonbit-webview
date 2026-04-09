#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "moonbit.h"

#ifdef _WIN32
#define CINTERFACE
#define COBJMACROS
#include <windows.h>
#include <ole2.h>
#include "../../build/_deps/microsoft_web_webview2-src/build/native/include/WebView2.h"
#ifdef _MSC_VER
#pragma comment(lib, "ole32.lib")
#endif
#endif

typedef struct lepus_runtime_asset_origin_state lepus_runtime_asset_origin_state_t;

#ifdef _WIN32
static HRESULT STDMETHODCALLTYPE
lepus_runtime_asset_origin_query_interface(
    ICoreWebView2WebResourceRequestedEventHandler *self,
    REFIID riid,
    void **ppv_object);
static ULONG STDMETHODCALLTYPE
lepus_runtime_asset_origin_add_ref(
    ICoreWebView2WebResourceRequestedEventHandler *self);
static ULONG STDMETHODCALLTYPE
lepus_runtime_asset_origin_release(
    ICoreWebView2WebResourceRequestedEventHandler *self);
static HRESULT STDMETHODCALLTYPE
lepus_runtime_asset_origin_invoke(
    ICoreWebView2WebResourceRequestedEventHandler *self,
    ICoreWebView2 *sender,
    ICoreWebView2WebResourceRequestedEventArgs *args);

static ICoreWebView2WebResourceRequestedEventHandlerVtbl
    lepus_runtime_asset_origin_vtbl = {
        lepus_runtime_asset_origin_query_interface,
        lepus_runtime_asset_origin_add_ref,
        lepus_runtime_asset_origin_release,
        lepus_runtime_asset_origin_invoke,
};

struct lepus_runtime_asset_origin_state {
  ICoreWebView2WebResourceRequestedEventHandler iface;
  LONG ref_count;
  ICoreWebView2 *webview;
  ICoreWebView2_3 *webview3;
  ICoreWebView2Environment *environment;
  EventRegistrationToken token;
  int has_token;
  wchar_t *host;
  wchar_t *root_dir;
  wchar_t *default_entry;
  wchar_t *filter_uri;
};

static wchar_t *lepus_runtime_duplicate_wstr(const wchar_t *value) {
  size_t len;
  wchar_t *copy;
  if (value == NULL) {
    return NULL;
  }
  len = wcslen(value);
  copy = (wchar_t *)calloc(len + 1, sizeof(wchar_t));
  if (copy == NULL) {
    return NULL;
  }
  memcpy(copy, value, (len + 1) * sizeof(wchar_t));
  return copy;
}

static wchar_t *lepus_runtime_duplicate_wstr_n(const wchar_t *value, size_t len) {
  wchar_t *copy = (wchar_t *)calloc(len + 1, sizeof(wchar_t));
  if (copy == NULL) {
    return NULL;
  }
  if (len > 0) {
    memcpy(copy, value, len * sizeof(wchar_t));
  }
  copy[len] = L'\0';
  return copy;
}

static wchar_t *lepus_runtime_build_filter_uri(const wchar_t *host) {
  static const wchar_t prefix[] = L"https://";
  static const wchar_t suffix[] = L"/*";
  size_t prefix_len = wcslen(prefix);
  size_t host_len = wcslen(host);
  size_t suffix_len = wcslen(suffix);
  wchar_t *value =
      (wchar_t *)calloc(prefix_len + host_len + suffix_len + 1, sizeof(wchar_t));
  if (value == NULL) {
    return NULL;
  }
  memcpy(value, prefix, prefix_len * sizeof(wchar_t));
  memcpy(value + prefix_len, host, host_len * sizeof(wchar_t));
  memcpy(value + prefix_len + host_len, suffix, (suffix_len + 1) * sizeof(wchar_t));
  return value;
}

static int lepus_runtime_hex_value(wchar_t ch) {
  if (ch >= L'0' && ch <= L'9') {
    return (int)(ch - L'0');
  }
  if (ch >= L'a' && ch <= L'f') {
    return 10 + (int)(ch - L'a');
  }
  if (ch >= L'A' && ch <= L'F') {
    return 10 + (int)(ch - L'A');
  }
  return -1;
}

static wchar_t *lepus_runtime_percent_decode_path(const wchar_t *value) {
  size_t src = 0;
  size_t dst = 0;
  size_t len = wcslen(value);
  wchar_t *decoded = (wchar_t *)calloc(len + 1, sizeof(wchar_t));
  if (decoded == NULL) {
    return NULL;
  }
  while (value[src] != L'\0') {
    if (value[src] == L'%' && value[src + 1] != L'\0' && value[src + 2] != L'\0') {
      int hi = lepus_runtime_hex_value(value[src + 1]);
      int lo = lepus_runtime_hex_value(value[src + 2]);
      if (hi >= 0 && lo >= 0) {
        decoded[dst++] = (wchar_t)((hi << 4) | lo);
        src += 3;
        continue;
      }
    }
    decoded[dst++] = value[src++];
  }
  decoded[dst] = L'\0';
  return decoded;
}

static int lepus_runtime_is_safe_relative_path(const wchar_t *path) {
  const wchar_t *cursor = path;
  if (path == NULL || path[0] == L'\0') {
    return 1;
  }
  if (path[0] == L'/' || path[0] == L'\\') {
    return 0;
  }
  while (*cursor != L'\0') {
    size_t segment_len = 0;
    const wchar_t *segment_start = cursor;
    while (cursor[segment_len] != L'\0' && cursor[segment_len] != L'/' &&
           cursor[segment_len] != L'\\') {
      if (cursor[segment_len] == L':') {
        return 0;
      }
      segment_len += 1;
    }
    if (segment_len == 2 && segment_start[0] == L'.' && segment_start[1] == L'.') {
      return 0;
    }
    cursor += segment_len;
    if (*cursor == L'/' || *cursor == L'\\') {
      cursor += 1;
    }
  }
  return 1;
}

static void lepus_runtime_normalize_separators(wchar_t *path) {
  size_t idx = 0;
  while (path[idx] != L'\0') {
    if (path[idx] == L'/') {
      path[idx] = L'\\';
    }
    idx += 1;
  }
}

static int lepus_runtime_path_has_html_extension(const wchar_t *path) {
  size_t len = wcslen(path);
  if (len < 5) {
    return 0;
  }
  return _wcsicmp(path + len - 5, L".html") == 0;
}

static const wchar_t *lepus_runtime_content_type_for_path(const wchar_t *path) {
  size_t len = wcslen(path);
  if (len >= 5 && _wcsicmp(path + len - 5, L".html") == 0) {
    return L"text/html; charset=utf-8";
  }
  if (len >= 4 && _wcsicmp(path + len - 4, L".css") == 0) {
    return L"text/css; charset=utf-8";
  }
  if ((len >= 3 && _wcsicmp(path + len - 3, L".js") == 0) ||
      (len >= 4 && _wcsicmp(path + len - 4, L".mjs") == 0)) {
    return L"text/javascript; charset=utf-8";
  }
  if ((len >= 5 && _wcsicmp(path + len - 5, L".json") == 0) ||
      (len >= 4 && _wcsicmp(path + len - 4, L".map") == 0)) {
    return L"application/json; charset=utf-8";
  }
  if (len >= 4 && _wcsicmp(path + len - 4, L".svg") == 0) {
    return L"image/svg+xml";
  }
  if (len >= 4 && _wcsicmp(path + len - 4, L".png") == 0) {
    return L"image/png";
  }
  if ((len >= 4 && _wcsicmp(path + len - 4, L".jpg") == 0) ||
      (len >= 5 && _wcsicmp(path + len - 5, L".jpeg") == 0)) {
    return L"image/jpeg";
  }
  if (len >= 4 && _wcsicmp(path + len - 4, L".gif") == 0) {
    return L"image/gif";
  }
  if (len >= 5 && _wcsicmp(path + len - 5, L".wasm") == 0) {
    return L"application/wasm";
  }
  if (len >= 5 && _wcsicmp(path + len - 5, L".woff") == 0) {
    return L"font/woff";
  }
  if (len >= 6 && _wcsicmp(path + len - 6, L".woff2") == 0) {
    return L"font/woff2";
  }
  if (len >= 4 && _wcsicmp(path + len - 4, L".txt") == 0) {
    return L"text/plain; charset=utf-8";
  }
  return L"application/octet-stream";
}

static wchar_t *lepus_runtime_build_relative_document_path(
    const wchar_t *uri,
    const wchar_t *host,
    const wchar_t *default_entry) {
  static const wchar_t scheme[] = L"https://";
  size_t scheme_len = wcslen(scheme);
  size_t host_len = wcslen(host);
  const wchar_t *path_start;
  const wchar_t *path_end;
  wchar_t *uri_path;
  wchar_t *decoded_path;
  if (wcsncmp(uri, scheme, scheme_len) != 0) {
    return NULL;
  }
  if (_wcsnicmp(uri + scheme_len, host, host_len) != 0) {
    return NULL;
  }
  path_start = uri + scheme_len + host_len;
  if (*path_start == L'\0') {
    return lepus_runtime_duplicate_wstr(default_entry);
  }
  if (*path_start != L'/') {
    return NULL;
  }
  path_end = path_start;
  while (*path_end != L'\0' && *path_end != L'?' && *path_end != L'#') {
    path_end += 1;
  }
  uri_path = lepus_runtime_duplicate_wstr_n(path_start, (size_t)(path_end - path_start));
  if (uri_path == NULL) {
    return NULL;
  }
  if (wcscmp(uri_path, L"/") == 0) {
    free(uri_path);
    return lepus_runtime_duplicate_wstr(default_entry);
  }
  if (uri_path[wcslen(uri_path) - 1] == L'/') {
    size_t len = wcslen(uri_path);
    wchar_t *index_path = (wchar_t *)calloc(len + 11, sizeof(wchar_t));
    if (index_path == NULL) {
      free(uri_path);
      return NULL;
    }
    memcpy(index_path, uri_path + 1, (len - 1) * sizeof(wchar_t));
    memcpy(index_path + len - 1, L"index.html", 11 * sizeof(wchar_t));
    free(uri_path);
    decoded_path = lepus_runtime_percent_decode_path(index_path);
    free(index_path);
  } else {
    decoded_path = lepus_runtime_percent_decode_path(uri_path + 1);
    free(uri_path);
  }
  if (decoded_path == NULL) {
    return NULL;
  }
  lepus_runtime_normalize_separators(decoded_path);
  if (!lepus_runtime_is_safe_relative_path(decoded_path)) {
    free(decoded_path);
    return NULL;
  }
  return decoded_path;
}

static wchar_t *lepus_runtime_join_path(
    const wchar_t *root_dir,
    const wchar_t *relative_path) {
  size_t root_len = wcslen(root_dir);
  size_t relative_len = wcslen(relative_path);
  int needs_sep = root_len > 0 && root_dir[root_len - 1] != L'\\' &&
                  root_dir[root_len - 1] != L'/';
  wchar_t *full_path = (wchar_t *)calloc(
      root_len + relative_len + (needs_sep ? 2 : 1), sizeof(wchar_t));
  if (full_path == NULL) {
    return NULL;
  }
  memcpy(full_path, root_dir, root_len * sizeof(wchar_t));
  if (needs_sep) {
    full_path[root_len] = L'\\';
  }
  memcpy(full_path + root_len + (needs_sep ? 1 : 0),
         relative_path,
         (relative_len + 1) * sizeof(wchar_t));
  return full_path;
}

static HRESULT lepus_runtime_read_file_bytes(
    const wchar_t *path,
    BYTE **data,
    SIZE_T *size) {
  FILE *file = _wfopen(path, L"rb");
  long file_size;
  size_t bytes_read;
  BYTE *buffer;
  if (file == NULL) {
    return HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND);
  }
  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    return E_FAIL;
  }
  file_size = ftell(file);
  if (file_size < 0) {
    fclose(file);
    return E_FAIL;
  }
  if (fseek(file, 0, SEEK_SET) != 0) {
    fclose(file);
    return E_FAIL;
  }
  buffer = (BYTE *)malloc((size_t)(file_size == 0 ? 1 : file_size));
  if (buffer == NULL) {
    fclose(file);
    return E_OUTOFMEMORY;
  }
  bytes_read = fread(buffer, 1, (size_t)file_size, file);
  fclose(file);
  if (bytes_read != (size_t)file_size) {
    free(buffer);
    return E_FAIL;
  }
  *data = buffer;
  *size = (SIZE_T)file_size;
  return S_OK;
}

static HRESULT lepus_runtime_create_stream_from_bytes(
    BYTE *data,
    SIZE_T size,
    IStream **stream) {
  HGLOBAL memory = GlobalAlloc(GMEM_MOVEABLE, size == 0 ? 1 : size);
  void *buffer;
  if (memory == NULL) {
    return E_OUTOFMEMORY;
  }
  buffer = GlobalLock(memory);
  if (buffer == NULL) {
    GlobalFree(memory);
    return E_OUTOFMEMORY;
  }
  if (size > 0) {
    memcpy(buffer, data, size);
  }
  GlobalUnlock(memory);
  return CreateStreamOnHGlobal(memory, TRUE, stream);
}

static HRESULT lepus_runtime_set_response(
    lepus_runtime_asset_origin_state_t *state,
    ICoreWebView2WebResourceRequestedEventArgs *args,
    int status_code,
    const wchar_t *reason_phrase,
    const wchar_t *content_type,
    const BYTE *body,
    SIZE_T body_size) {
  static const wchar_t security_headers[] =
      L"Cross-Origin-Opener-Policy: same-origin\r\n"
      L"Cross-Origin-Embedder-Policy: require-corp\r\n"
      L"Cross-Origin-Resource-Policy: same-origin\r\n"
      L"X-Content-Type-Options: nosniff\r\n"
      L"Cache-Control: no-cache\r\n";
  wchar_t *headers;
  IStream *stream = NULL;
  ICoreWebView2WebResourceResponse *response = NULL;
  HRESULT hr;
  size_t header_len = wcslen(L"Content-Type: ") + wcslen(content_type) +
                      wcslen(L"\r\n") + wcslen(security_headers) + 1;
  headers = (wchar_t *)calloc(header_len, sizeof(wchar_t));
  if (headers == NULL) {
    return E_OUTOFMEMORY;
  }
  wcscpy(headers, L"Content-Type: ");
  wcscat(headers, content_type);
  wcscat(headers, L"\r\n");
  wcscat(headers, security_headers);
  hr = lepus_runtime_create_stream_from_bytes((BYTE *)body, body_size, &stream);
  if (FAILED(hr)) {
    free(headers);
    return hr;
  }
  hr = ICoreWebView2Environment_CreateWebResourceResponse(
      state->environment,
      stream,
      status_code,
      reason_phrase,
      headers,
      &response);
  if (SUCCEEDED(hr)) {
    hr = ICoreWebView2WebResourceRequestedEventArgs_put_Response(args, response);
  }
  if (response != NULL) {
    ICoreWebView2WebResourceResponse_Release(response);
  }
  if (stream != NULL) {
    IStream_Release(stream);
  }
  free(headers);
  return hr;
}

static void lepus_runtime_asset_origin_free(
    lepus_runtime_asset_origin_state_t *state) {
  if (state == NULL) {
    return;
  }
  free(state->filter_uri);
  free(state->default_entry);
  free(state->root_dir);
  free(state->host);
  free(state);
}

static HRESULT STDMETHODCALLTYPE
lepus_runtime_asset_origin_query_interface(
    ICoreWebView2WebResourceRequestedEventHandler *self,
    REFIID riid,
    void **ppv_object) {
  if (ppv_object == NULL) {
    return E_POINTER;
  }
  *ppv_object = NULL;
  if (IsEqualIID(riid, &IID_IUnknown) ||
      IsEqualIID(riid, &IID_ICoreWebView2WebResourceRequestedEventHandler)) {
    *ppv_object = self;
    lepus_runtime_asset_origin_add_ref(self);
    return S_OK;
  }
  return E_NOINTERFACE;
}

static ULONG STDMETHODCALLTYPE
lepus_runtime_asset_origin_add_ref(
    ICoreWebView2WebResourceRequestedEventHandler *self) {
  lepus_runtime_asset_origin_state_t *state =
      (lepus_runtime_asset_origin_state_t *)self;
  return (ULONG)InterlockedIncrement(&state->ref_count);
}

static ULONG STDMETHODCALLTYPE
lepus_runtime_asset_origin_release(
    ICoreWebView2WebResourceRequestedEventHandler *self) {
  lepus_runtime_asset_origin_state_t *state =
      (lepus_runtime_asset_origin_state_t *)self;
  ULONG count = (ULONG)InterlockedDecrement(&state->ref_count);
  if (count == 0) {
    lepus_runtime_asset_origin_free(state);
  }
  return count;
}

static HRESULT STDMETHODCALLTYPE
lepus_runtime_asset_origin_invoke(
    ICoreWebView2WebResourceRequestedEventHandler *self,
    ICoreWebView2 *sender,
    ICoreWebView2WebResourceRequestedEventArgs *args) {
  lepus_runtime_asset_origin_state_t *state =
      (lepus_runtime_asset_origin_state_t *)self;
  ICoreWebView2WebResourceRequest *request = NULL;
  LPWSTR uri = NULL;
  wchar_t *relative_path = NULL;
  wchar_t *full_path = NULL;
  BYTE *data = NULL;
  SIZE_T data_size = 0;
  HRESULT hr = ICoreWebView2WebResourceRequestedEventArgs_get_Request(args, &request);
  (void)sender;
  if (FAILED(hr)) {
    return hr;
  }
  hr = ICoreWebView2WebResourceRequest_get_Uri(request, &uri);
  if (FAILED(hr)) {
    ICoreWebView2WebResourceRequest_Release(request);
    return hr;
  }
  relative_path = lepus_runtime_build_relative_document_path(
      uri, state->host, state->default_entry);
  if (relative_path == NULL) {
    static const BYTE body[] = "Not Found";
    hr = lepus_runtime_set_response(
        state, args, 404, L"Not Found", L"text/plain; charset=utf-8", body,
        sizeof(body) - 1);
    goto cleanup;
  }
  full_path = lepus_runtime_join_path(state->root_dir, relative_path);
  if (full_path == NULL) {
    hr = E_OUTOFMEMORY;
    goto cleanup;
  }
  hr = lepus_runtime_read_file_bytes(full_path, &data, &data_size);
  if (FAILED(hr)) {
    static const BYTE body[] = "Not Found";
    hr = lepus_runtime_set_response(
        state, args, 404, L"Not Found", L"text/plain; charset=utf-8", body,
        sizeof(body) - 1);
    goto cleanup;
  }
  hr = lepus_runtime_set_response(
      state,
      args,
      200,
      L"OK",
      lepus_runtime_content_type_for_path(relative_path),
      data,
      data_size);

cleanup:
  if (data != NULL) {
    free(data);
  }
  free(full_path);
  free(relative_path);
  if (uri != NULL) {
    CoTaskMemFree(uri);
  }
  ICoreWebView2WebResourceRequest_Release(request);
  return hr;
}
#endif

MOONBIT_FFI_EXPORT int32_t lepus_runtime_asset_origin_is_windows(void) {
#ifdef _WIN32
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT lepus_runtime_asset_origin_state_t *
lepus_runtime_asset_origin_install(
    int64_t controller_handle,
    moonbit_bytes_t host,
    moonbit_bytes_t root_dir,
    moonbit_bytes_t default_entry) {
#ifdef _WIN32
  ICoreWebView2Controller *controller =
      (ICoreWebView2Controller *)(uintptr_t)controller_handle;
  lepus_runtime_asset_origin_state_t *state = NULL;
  HRESULT hr;
  if (controller == NULL) {
    return NULL;
  }
  state = (lepus_runtime_asset_origin_state_t *)calloc(1, sizeof(*state));
  if (state == NULL) {
    return NULL;
  }
  state->iface.lpVtbl = &lepus_runtime_asset_origin_vtbl;
  /*
   * Keep one extra process-lifetime reference on purpose. WebView2 teardown can
   * outlive the MoonBit window lifecycle, and touching COM cleanup eagerly here
   * has proven crash-prone. The remaining reference is intentionally leaked for
   * now so asset-backed windows stay stable.
   */
  state->ref_count = 2;
  state->host = lepus_runtime_duplicate_wstr((const wchar_t *)host);
  state->root_dir = lepus_runtime_duplicate_wstr((const wchar_t *)root_dir);
  state->default_entry = lepus_runtime_duplicate_wstr((const wchar_t *)default_entry);
  if (state->host == NULL || state->root_dir == NULL || state->default_entry == NULL) {
    lepus_runtime_asset_origin_free(state);
    return NULL;
  }
  state->filter_uri = lepus_runtime_build_filter_uri(state->host);
  if (state->filter_uri == NULL) {
    lepus_runtime_asset_origin_free(state);
    return NULL;
  }
  hr = ICoreWebView2Controller_get_CoreWebView2(controller, &state->webview);
  if (FAILED(hr)) {
    lepus_runtime_asset_origin_free(state);
    return NULL;
  }
  hr = ICoreWebView2_QueryInterface(
      state->webview, &IID_ICoreWebView2_3, (void **)&state->webview3);
  if (FAILED(hr)) {
    lepus_runtime_asset_origin_free(state);
    return NULL;
  }
  hr = ICoreWebView2_3_get_Environment(state->webview3, &state->environment);
  if (FAILED(hr)) {
    lepus_runtime_asset_origin_free(state);
    return NULL;
  }
  hr = ICoreWebView2_AddWebResourceRequestedFilter(
      state->webview,
      state->filter_uri,
      COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL);
  if (FAILED(hr)) {
    lepus_runtime_asset_origin_free(state);
    return NULL;
  }
  hr = ICoreWebView2_add_WebResourceRequested(
      state->webview, &state->iface, &state->token);
  if (FAILED(hr)) {
    ICoreWebView2_RemoveWebResourceRequestedFilter(
        state->webview,
        state->filter_uri,
        COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL);
    lepus_runtime_asset_origin_free(state);
    return NULL;
  }
  state->has_token = 1;
  return state;
#else
  (void)controller_handle;
  (void)host;
  (void)root_dir;
  (void)default_entry;
  return NULL;
#endif
}

MOONBIT_FFI_EXPORT void lepus_runtime_asset_origin_destroy(
    lepus_runtime_asset_origin_state_t *state) {
#ifdef _WIN32
  (void)state;
#else
  (void)state;
#endif
}
