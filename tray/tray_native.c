#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "moonbit.h"

#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#ifdef _MSC_VER
#pragma comment(lib, "shell32.lib")
#endif
#endif

typedef struct desktop_tray_state {
  int64_t window_handle;
#ifdef _WIN32
  NOTIFYICONDATAW data;
#endif
  int32_t visible;
} desktop_tray_state_t;

MOONBIT_FFI_EXPORT int32_t desktop_tray_is_windows(void) {
#ifdef _WIN32
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT desktop_tray_state_t *desktop_tray_create(int64_t window_handle) {
  desktop_tray_state_t *state =
      (desktop_tray_state_t *)calloc(1, sizeof(desktop_tray_state_t));
  if (state == NULL) {
    return NULL;
  }
  state->window_handle = window_handle;
#ifdef _WIN32
  memset(&state->data, 0, sizeof(state->data));
  state->data.cbSize = sizeof(state->data);
  state->data.hWnd = (HWND)(uintptr_t)window_handle;
  state->data.uID = 0x5742;
  state->data.uFlags = NIF_ICON | NIF_TIP;
  state->data.hIcon = LoadIconW(NULL, (LPCWSTR)IDI_APPLICATION);
  state->data.dwState = 0;
  state->data.dwStateMask = 0;
#endif
  state->visible = 0;
  return state;
}

MOONBIT_FFI_EXPORT void desktop_tray_destroy(desktop_tray_state_t *state) {
  if (state == NULL) {
    return;
  }
#ifdef _WIN32
  if (state->visible) {
    Shell_NotifyIconW(NIM_DELETE, &state->data);
  }
#endif
  free(state);
}

#ifdef _WIN32
static void desktop_tray_copy_tooltip(
    desktop_tray_state_t *state,
    const wchar_t *tooltip) {
  if (tooltip == NULL) {
    state->data.szTip[0] = L'\0';
    return;
  }
  wcsncpy(state->data.szTip, tooltip, 127);
  state->data.szTip[127] = L'\0';
}
#endif

MOONBIT_FFI_EXPORT int32_t desktop_tray_show(
    desktop_tray_state_t *state,
    moonbit_bytes_t tooltip) {
#ifdef _WIN32
  if (state == NULL) {
    return 0;
  }
  desktop_tray_copy_tooltip(state, (const wchar_t *)tooltip);
  if (state->visible) {
    return Shell_NotifyIconW(NIM_MODIFY, &state->data);
  }
  if (!Shell_NotifyIconW(NIM_ADD, &state->data)) {
    return 0;
  }
  state->visible = 1;
  return 1;
#else
  (void)state;
  (void)tooltip;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t desktop_tray_hide(desktop_tray_state_t *state) {
#ifdef _WIN32
  if (state == NULL) {
    return 0;
  }
  if (!state->visible) {
    return 1;
  }
  if (!Shell_NotifyIconW(NIM_DELETE, &state->data)) {
    return 0;
  }
  state->visible = 0;
  return 1;
#else
  (void)state;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t desktop_tray_set_tooltip(
    desktop_tray_state_t *state,
    moonbit_bytes_t tooltip) {
#ifdef _WIN32
  if (state == NULL) {
    return 0;
  }
  desktop_tray_copy_tooltip(state, (const wchar_t *)tooltip);
  if (!state->visible) {
    return 1;
  }
  return Shell_NotifyIconW(NIM_MODIFY, &state->data);
#else
  (void)state;
  (void)tooltip;
  return 0;
#endif
}
