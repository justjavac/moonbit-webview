#include <stdint.h>
#include <string.h>
#include <wchar.h>

#include "moonbit.h"

#ifdef _WIN32
#include <windows.h>
#include <commdlg.h>
#ifdef _MSC_VER
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "comdlg32.lib")
#endif
#endif

static moonbit_bytes_t extensions_dialog_copy_wstr(const wchar_t *value) {
  size_t len = wcslen(value);
  size_t size = (len + 1) * sizeof(wchar_t);
  moonbit_bytes_t bytes = moonbit_make_bytes((int32_t)size, 0);
  memcpy(bytes, value, size);
  return bytes;
}

MOONBIT_FFI_EXPORT int32_t extensions_dialog_is_windows(void) {
#ifdef _WIN32
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t extensions_dialog_message(
    int64_t window_handle,
    moonbit_bytes_t title,
    moonbit_bytes_t message,
    int32_t level) {
#ifdef _WIN32
  UINT flags = MB_OK;
  switch (level) {
  case 1:
    flags |= MB_ICONWARNING;
    break;
  case 2:
    flags |= MB_ICONERROR;
    break;
  default:
    flags |= MB_ICONINFORMATION;
    break;
  }
  return MessageBoxW((HWND)(uintptr_t)window_handle,
                     (const wchar_t *)message,
                     (const wchar_t *)title,
                     flags);
#else
  (void)window_handle;
  (void)title;
  (void)message;
  (void)level;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t extensions_dialog_confirm(
    int64_t window_handle,
    moonbit_bytes_t title,
    moonbit_bytes_t message,
    int32_t level) {
#ifdef _WIN32
  UINT flags = MB_OKCANCEL;
  switch (level) {
  case 1:
    flags |= MB_ICONWARNING;
    break;
  case 2:
    flags |= MB_ICONERROR;
    break;
  default:
    flags |= MB_ICONQUESTION;
    break;
  }
  return MessageBoxW((HWND)(uintptr_t)window_handle,
                     (const wchar_t *)message,
                     (const wchar_t *)title,
                     flags) == IDOK;
#else
  (void)window_handle;
  (void)title;
  (void)message;
  (void)level;
  return 0;
#endif
}

static moonbit_bytes_t extensions_dialog_run_file_dialog(
    int64_t window_handle,
    moonbit_bytes_t title,
    moonbit_bytes_t path,
    int save_mode) {
#ifdef _WIN32
  wchar_t file_buffer[4096] = L"";
  const wchar_t *initial_path = (const wchar_t *)path;
  const wchar_t filter[] = L"All Files\0*.*\0\0";
  OPENFILENAMEW dialog = {0};

  if (initial_path[0] != L'\0') {
    wcsncpy(file_buffer, initial_path, 4095);
    file_buffer[4095] = L'\0';
  }

  dialog.lStructSize = sizeof(dialog);
  dialog.hwndOwner = (HWND)(uintptr_t)window_handle;
  dialog.lpstrFilter = filter;
  dialog.lpstrFile = file_buffer;
  dialog.nMaxFile = sizeof(file_buffer) / sizeof(file_buffer[0]);
  dialog.lpstrTitle = ((const wchar_t *)title)[0] == L'\0'
                          ? NULL
                          : (const wchar_t *)title;
  dialog.Flags = OFN_EXPLORER | OFN_PATHMUSTEXIST;
  if (save_mode) {
    dialog.Flags |= OFN_OVERWRITEPROMPT;
    if (GetSaveFileNameW(&dialog)) {
      return extensions_dialog_copy_wstr(file_buffer);
    }
  } else {
    dialog.Flags |= OFN_FILEMUSTEXIST;
    if (GetOpenFileNameW(&dialog)) {
      return extensions_dialog_copy_wstr(file_buffer);
    }
  }
  return extensions_dialog_copy_wstr(L"");
#else
  (void)window_handle;
  (void)title;
  (void)path;
  (void)save_mode;
  return extensions_dialog_copy_wstr(L"");
#endif
}

MOONBIT_FFI_EXPORT moonbit_bytes_t extensions_dialog_open_file(
    int64_t window_handle,
    moonbit_bytes_t title,
    moonbit_bytes_t path) {
  return extensions_dialog_run_file_dialog(window_handle, title, path, 0);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t extensions_dialog_save_file(
    int64_t window_handle,
    moonbit_bytes_t title,
    moonbit_bytes_t path) {
  return extensions_dialog_run_file_dialog(window_handle, title, path, 1);
}
