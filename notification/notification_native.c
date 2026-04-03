#include <stdint.h>

#include "moonbit.h"

#ifdef _WIN32
#define COBJMACROS
#include <objbase.h>
#include <shobjidl.h>
#include <windows.h>
#ifdef _MSC_VER
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shell32.lib")
#endif
#endif

MOONBIT_FFI_EXPORT int32_t desktop_notification_is_windows(void) {
#ifdef _WIN32
  return 1;
#else
  return 0;
#endif
}

#ifdef _WIN32
static HICON desktop_notification_level_icon(int32_t level) {
  switch (level) {
  case 1:
    return LoadIconW(NULL, (LPCWSTR)IDI_WARNING);
  case 2:
    return LoadIconW(NULL, (LPCWSTR)IDI_ERROR);
  default:
    return LoadIconW(NULL, (LPCWSTR)IDI_INFORMATION);
  }
}

static DWORD desktop_notification_info_flags(int32_t level) {
  switch (level) {
  case 1:
    return NIIF_WARNING;
  case 2:
    return NIIF_ERROR;
  default:
    return NIIF_INFO;
  }
}
#endif

MOONBIT_FFI_EXPORT int32_t desktop_notification_show(
    int64_t window_handle,
    moonbit_bytes_t title,
    moonbit_bytes_t body,
    int32_t level) {
#ifdef _WIN32
  const wchar_t *title_text = (const wchar_t *)title;
  const wchar_t *body_text = (const wchar_t *)body;
  const wchar_t *tooltip_text = title_text;
  HRESULT hr;
  int initialized = 0;
  IUserNotification *notification = NULL;
  HICON icon = desktop_notification_level_icon(level);

  (void)window_handle;

  if (title_text == NULL || title_text[0] == L'\0') {
    title_text = L"MoonBit";
    tooltip_text = L"MoonBit";
  }
  if (body_text == NULL || body_text[0] == L'\0') {
    return 0;
  }

  hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
  if (SUCCEEDED(hr)) {
    initialized = 1;
  } else if (hr != RPC_E_CHANGED_MODE) {
    return 0;
  }

  hr = CoCreateInstance(&CLSID_UserNotification, NULL, CLSCTX_INPROC_SERVER,
                        &IID_IUserNotification, (void **)&notification);
  if (FAILED(hr) || notification == NULL) {
    if (initialized) {
      CoUninitialize();
    }
    return 0;
  }

  hr = IUserNotification_SetIconInfo(notification, icon, tooltip_text);
  if (FAILED(hr)) {
    IUserNotification_Release(notification);
    if (initialized) {
      CoUninitialize();
    }
    return 0;
  }

  hr = IUserNotification_SetBalloonInfo(
      notification, title_text, body_text, desktop_notification_info_flags(level));
  if (FAILED(hr)) {
    IUserNotification_Release(notification);
    if (initialized) {
      CoUninitialize();
    }
    return 0;
  }

  hr = IUserNotification_Show(notification, NULL, 5000);
  IUserNotification_Release(notification);
  if (initialized) {
    CoUninitialize();
  }
  return SUCCEEDED(hr);
#else
  (void)window_handle;
  (void)title;
  (void)body;
  (void)level;
  return 0;
#endif
}
