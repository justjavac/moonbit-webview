#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <direct.h>
#include <io.h>
#else
#include <unistd.h>
#endif

#include "moonbit.h"

static moonbit_bytes_t extensions_fs_make_bytes(const char *buffer, size_t len) {
  moonbit_bytes_t result = moonbit_make_bytes((int32_t)(len + 1), 0);
  if (len > 0) {
    memcpy(result, buffer, len);
  }
  result[len] = '\0';
  return result;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t extensions_fs_last_error_message(void) {
  const char *message = strerror(errno);
  size_t len = strlen(message);
  return extensions_fs_make_bytes(message, len);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t extensions_fs_stat_json_ffi(moonbit_bytes_t path) {
  struct stat info;
  char buffer[256];
  int exists = stat((const char *)path, &info) == 0;
  long long size = 0;
  int is_file = 0;
  int is_dir = 0;
  int readonly = 0;
  int written;

  if (exists) {
    size = (long long)info.st_size;
#ifdef _WIN32
    is_dir = (info.st_mode & _S_IFDIR) != 0;
    is_file = (info.st_mode & _S_IFREG) != 0;
#else
    is_dir = S_ISDIR(info.st_mode);
    is_file = S_ISREG(info.st_mode);
#endif
    #ifdef _WIN32
    readonly = _access((const char *)path, 2) != 0;
    #else
    readonly = access((const char *)path, W_OK) != 0;
    #endif
  }

  written = snprintf(
      buffer,
      sizeof(buffer),
      "{\"exists\":%s,\"size\":%lld,\"is_file\":%s,\"is_dir\":%s,\"is_readonly\":%s}",
      exists ? "true" : "false",
      size,
      is_file ? "true" : "false",
      is_dir ? "true" : "false",
      readonly ? "true" : "false");
  if (written < 0) {
    return extensions_fs_make_bytes("", 0);
  }
  if ((size_t)written >= sizeof(buffer)) {
    written = (int)sizeof(buffer) - 1;
  }
  return extensions_fs_make_bytes(buffer, (size_t)written);
}

MOONBIT_FFI_EXPORT int32_t extensions_fs_rename_ffi(moonbit_bytes_t old_path,
                                                    moonbit_bytes_t new_path) {
  return rename((const char *)old_path, (const char *)new_path);
}

MOONBIT_FFI_EXPORT int32_t extensions_fs_copy_file_ffi(moonbit_bytes_t src,
                                                       moonbit_bytes_t dest,
                                                       int32_t overwrite) {
  char buffer[8192];
  FILE *src_file;
  FILE *dest_file;
  long long total = 0;
  size_t read_count;

  if (!overwrite) {
    struct stat existing;
    if (stat((const char *)dest, &existing) == 0) {
      errno = EEXIST;
      return -1;
    }
  }

  src_file = fopen((const char *)src, "rb");
  if (src_file == NULL) {
    return -1;
  }

  dest_file = fopen((const char *)dest, "wb");
  if (dest_file == NULL) {
    fclose(src_file);
    return -1;
  }

  while ((read_count = fread(buffer, 1, sizeof(buffer), src_file)) > 0) {
    if (fwrite(buffer, 1, read_count, dest_file) != read_count) {
      fclose(src_file);
      fclose(dest_file);
      return -1;
    }
    total += (long long)read_count;
  }

  if (ferror(src_file) != 0 || fflush(dest_file) != 0) {
    fclose(src_file);
    fclose(dest_file);
    return -1;
  }

  if (fclose(src_file) != 0 || fclose(dest_file) != 0) {
    return -1;
  }

  if (total > INT32_MAX) {
    errno = EFBIG;
    return -1;
  }

  return (int32_t)total;
}

MOONBIT_FFI_EXPORT int32_t extensions_fs_append_bytes_ffi(moonbit_bytes_t path,
                                                          moonbit_bytes_t content,
                                                          int32_t content_len) {
  FILE *file = fopen((const char *)path, "ab");
  size_t written;

  if (file == NULL) {
    return -1;
  }

  written = fwrite(content, 1, (size_t)content_len, file);
  if (written != (size_t)content_len || fflush(file) != 0 || fclose(file) != 0) {
    return -1;
  }

  if (written > INT32_MAX) {
    errno = EFBIG;
    return -1;
  }

  return (int32_t)written;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t extensions_fs_realpath_ffi(moonbit_bytes_t path) {
#ifdef _WIN32
  char buffer[4096];
  if (_fullpath(buffer, (const char *)path, sizeof(buffer)) == NULL) {
    return extensions_fs_make_bytes("", 0);
  }
  return extensions_fs_make_bytes(buffer, strlen(buffer));
#else
  char buffer[PATH_MAX];
  if (realpath((const char *)path, buffer) == NULL) {
    return extensions_fs_make_bytes("", 0);
  }
  return extensions_fs_make_bytes(buffer, strlen(buffer));
#endif
}

MOONBIT_FFI_EXPORT int32_t extensions_fs_truncate_file_ffi(moonbit_bytes_t path,
                                                           int32_t len) {
#ifdef _WIN32
  FILE *file = fopen((const char *)path, "r+b");
  int result;
  if (file == NULL) {
    return -1;
  }
  result = _chsize_s(_fileno(file), len);
  fclose(file);
  return result;
#else
  return truncate((const char *)path, len);
#endif
}

#ifdef __cplusplus
}
#endif
