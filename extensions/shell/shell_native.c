#include <stdint.h>
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

MOONBIT_FFI_EXPORT int32_t extensions_shell_is_windows(void) {
#ifdef _WIN32
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t extensions_shell_open(moonbit_bytes_t target) {
#ifdef _WIN32
  HINSTANCE result = ShellExecuteW(
      NULL, L"open", (const wchar_t *)target, NULL, NULL, SW_SHOWNORMAL);
  return (INT_PTR)result > 32;
#else
  (void)target;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t extensions_shell_reveal_item(moonbit_bytes_t path) {
#ifdef _WIN32
  const wchar_t *target = (const wchar_t *)path;
  size_t target_len = wcslen(target);
  size_t prefix_len = wcslen(L"/select,\"");
  size_t total_len = prefix_len + target_len + 2;
  wchar_t *parameters = (wchar_t *)malloc((total_len + 1) * sizeof(wchar_t));
  HINSTANCE result;

  if (parameters == NULL) {
    return 0;
  }

  wcscpy(parameters, L"/select,\"");
  wcscat(parameters, target);
  wcscat(parameters, L"\"");

  result = ShellExecuteW(
      NULL, L"open", L"explorer.exe", parameters, NULL, SW_SHOWNORMAL);
  free(parameters);
  return (INT_PTR)result > 32;
#else
  (void)path;
  return 0;
#endif
}
