#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dirent.h>
#include <unistd.h>
#endif

#include "moonbit.h"

static moonbit_bytes_t plugins_fs_copy_string(const char *value) {
  size_t len = strlen(value);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, value, len);
  return bytes;
}

static int plugins_fs_is_absolute_path(const char *path) {
#ifdef _WIN32
  return (strlen(path) >= 3 && path[1] == ':' &&
          (path[2] == '\\' || path[2] == '/')) ||
         (strlen(path) >= 2 && path[0] == '\\' && path[1] == '\\');
#else
  return path[0] == '/';
#endif
}

MOONBIT_FFI_EXPORT FILE *plugins_fs_fopen(moonbit_bytes_t path,
                                          moonbit_bytes_t mode) {
  return fopen((const char *)path, (const char *)mode);
}

MOONBIT_FFI_EXPORT size_t plugins_fs_fread(moonbit_bytes_t ptr, int size,
                                           int nitems, FILE *stream) {
  return fread(ptr, size, nitems, stream);
}

MOONBIT_FFI_EXPORT size_t plugins_fs_fwrite(moonbit_bytes_t ptr, int size,
                                            int nitems, FILE *stream) {
  return fwrite(ptr, size, nitems, stream);
}

MOONBIT_FFI_EXPORT int plugins_fs_fseek(FILE *stream, long offset, int whence) {
  return fseek(stream, offset, whence);
}

MOONBIT_FFI_EXPORT long plugins_fs_ftell(FILE *stream) { return ftell(stream); }

MOONBIT_FFI_EXPORT int plugins_fs_fflush(FILE *stream) { return fflush(stream); }

MOONBIT_FFI_EXPORT int plugins_fs_fclose(FILE *stream) { return fclose(stream); }

MOONBIT_FFI_EXPORT int plugins_fs_feof(FILE *stream) { return feof(stream); }

MOONBIT_FFI_EXPORT int plugins_fs_ferror(FILE *stream) { return ferror(stream); }

MOONBIT_FFI_EXPORT void plugins_fs_clearerr(FILE *stream) { clearerr(stream); }

MOONBIT_FFI_EXPORT moonbit_bytes_t plugins_fs_get_error_message(void) {
  const char *err_str = strerror(errno);
  size_t len = strlen(err_str);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, err_str, len);
  return bytes;
}

MOONBIT_FFI_EXPORT int plugins_fs_path_exists(moonbit_bytes_t path) {
  struct stat buffer;
  return stat((const char *)path, &buffer) == 0;
}

MOONBIT_FFI_EXPORT int plugins_fs_is_file(moonbit_bytes_t path) {
#ifdef _WIN32
  DWORD attrs = GetFileAttributes((const char *)path);
  if (attrs == INVALID_FILE_ATTRIBUTES) {
    return 0;
  }
  return !(attrs & FILE_ATTRIBUTE_DIRECTORY);
#else
  struct stat buffer;
  if (stat((const char *)path, &buffer) != 0) {
    return 0;
  }
  return S_ISREG(buffer.st_mode);
#endif
}

MOONBIT_FFI_EXPORT int plugins_fs_is_dir(moonbit_bytes_t path) {
#ifdef _WIN32
  DWORD attrs = GetFileAttributes((const char *)path);
  if (attrs == INVALID_FILE_ATTRIBUTES) {
    return 0;
  }
  return (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0;
#else
  struct stat buffer;
  if (stat((const char *)path, &buffer) != 0) {
    return 0;
  }
  return S_ISDIR(buffer.st_mode);
#endif
}

MOONBIT_FFI_EXPORT int plugins_fs_remove_file(moonbit_bytes_t path) {
  return remove((const char *)path);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t plugins_fs_absolute_path(
    moonbit_bytes_t path) {
  const char *input = (const char *)path;

#ifdef _WIN32
  DWORD length = GetFullPathNameA(input, 0, NULL, NULL);
  if (length == 0) {
    return plugins_fs_copy_string(input);
  }

  char *buffer = malloc(length);
  if (buffer == NULL) {
    return plugins_fs_copy_string(input);
  }

  DWORD written = GetFullPathNameA(input, length, buffer, NULL);
  if (written == 0 || written >= length) {
    free(buffer);
    return plugins_fs_copy_string(input);
  }

  moonbit_bytes_t result = plugins_fs_copy_string(buffer);
  free(buffer);
  return result;
#else
  char resolved[PATH_MAX];
  if (realpath(input, resolved) != NULL) {
    moonbit_bytes_t result = plugins_fs_copy_string(resolved);
    return result;
  }

  if (plugins_fs_is_absolute_path(input)) {
    return plugins_fs_copy_string(input);
  }

  char cwd[PATH_MAX];
  if (getcwd(cwd, sizeof(cwd)) == NULL) {
    return plugins_fs_copy_string(input);
  }

  size_t cwd_len = strlen(cwd);
  size_t input_len = strlen(input);
  char *joined = malloc(cwd_len + input_len + 2);
  if (joined == NULL) {
    return plugins_fs_copy_string(input);
  }

  memcpy(joined, cwd, cwd_len);
  joined[cwd_len] = '/';
  memcpy(joined + cwd_len + 1, input, input_len + 1);

  moonbit_bytes_t result = plugins_fs_copy_string(joined);
  free(joined);
  return result;
#endif
}

MOONBIT_FFI_EXPORT moonbit_bytes_t *plugins_fs_read_dir(moonbit_bytes_t path) {
#ifdef _WIN32
  WIN32_FIND_DATA find_data;
  HANDLE dir;
  moonbit_bytes_t *result = NULL;
  int count = 0;

  size_t path_len = strlen((const char *)path);
  char *search_path = malloc(path_len + 3);
  if (search_path == NULL) {
    return NULL;
  }

  sprintf(search_path, "%s\\*", (const char *)path);
  dir = FindFirstFile(search_path, &find_data);
  if (dir == INVALID_HANDLE_VALUE) {
    free(search_path);
    return NULL;
  }

  do {
    if (strcmp(find_data.cFileName, ".") != 0 &&
        strcmp(find_data.cFileName, "..") != 0) {
      count++;
    }
  } while (FindNextFile(dir, &find_data));

  FindClose(dir);
  dir = FindFirstFile(search_path, &find_data);
  free(search_path);
  if (dir == INVALID_HANDLE_VALUE) {
    return NULL;
  }

  result = (moonbit_bytes_t *)moonbit_make_ref_array(count, NULL);
  if (result == NULL) {
    FindClose(dir);
    return NULL;
  }

  int index = 0;
  do {
    if (strcmp(find_data.cFileName, ".") != 0 &&
        strcmp(find_data.cFileName, "..") != 0) {
      size_t name_len = strlen(find_data.cFileName);
      moonbit_bytes_t item = moonbit_make_bytes(name_len, 0);
      memcpy(item, find_data.cFileName, name_len);
      result[index++] = item;
    }
  } while (FindNextFile(dir, &find_data));

  FindClose(dir);
  return result;
#else
  DIR *dir;
  struct dirent *entry;
  moonbit_bytes_t *result = NULL;
  int count = 0;

  dir = opendir((const char *)path);
  if (dir == NULL) {
    return NULL;
  }

  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
      count++;
    }
  }

  rewinddir(dir);
  result = (moonbit_bytes_t *)moonbit_make_ref_array(count, NULL);
  if (result == NULL) {
    closedir(dir);
    return NULL;
  }

  int index = 0;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
      size_t name_len = strlen(entry->d_name);
      moonbit_bytes_t item = moonbit_make_bytes(name_len, 0);
      memcpy(item, entry->d_name, name_len);
      result[index++] = item;
    }
  }

  closedir(dir);
  return result;
#endif
}

#ifdef __cplusplus
}
#endif
