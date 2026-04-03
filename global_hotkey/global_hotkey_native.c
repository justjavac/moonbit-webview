#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "moonbit.h"

#ifdef _WIN32
#include <windows.h>
#endif

#ifdef _WIN32
#define DESKTOP_GLOBAL_SHORTCUT_MSG_REGISTER (WM_APP + 301)
#define DESKTOP_GLOBAL_SHORTCUT_MSG_UNREGISTER (WM_APP + 302)
#define DESKTOP_GLOBAL_SHORTCUT_MSG_QUIT (WM_APP + 303)
#endif

typedef struct desktop_global_shortcut_registration {
  int32_t id;
  char *accelerator;
  struct desktop_global_shortcut_registration *next;
} desktop_global_shortcut_registration_t;

typedef struct desktop_global_shortcut_trigger {
  int32_t id;
  struct desktop_global_shortcut_trigger *next;
} desktop_global_shortcut_trigger_t;

typedef struct desktop_global_shortcut_state {
#ifdef _WIN32
  HANDLE thread;
  HANDLE ready_event;
  DWORD thread_id;
  CRITICAL_SECTION lock;
#endif
  desktop_global_shortcut_registration_t *registrations;
  desktop_global_shortcut_trigger_t *triggered_head;
  desktop_global_shortcut_trigger_t *triggered_tail;
} desktop_global_shortcut_state_t;

#ifdef _WIN32
typedef struct desktop_global_shortcut_command {
  HANDLE done_event;
  int32_t success;
  int32_t id;
  int32_t modifiers;
  int32_t key;
  char *accelerator;
} desktop_global_shortcut_command_t;

static char *desktop_global_shortcut_strdup(const char *value) {
  size_t len;
  char *copy;
  if (value == NULL) {
    return NULL;
  }
  len = strlen(value);
  copy = (char *)malloc(len + 1);
  if (copy == NULL) {
    return NULL;
  }
  memcpy(copy, value, len + 1);
  return copy;
}

static void desktop_global_shortcut_free_registrations(
    desktop_global_shortcut_registration_t *registration) {
  while (registration != NULL) {
    desktop_global_shortcut_registration_t *next = registration->next;
    free(registration->accelerator);
    free(registration);
    registration = next;
  }
}

static void desktop_global_shortcut_free_triggers(
    desktop_global_shortcut_trigger_t *trigger) {
  while (trigger != NULL) {
    desktop_global_shortcut_trigger_t *next = trigger->next;
    free(trigger);
    trigger = next;
  }
}

static void desktop_global_shortcut_remove_registration(
    desktop_global_shortcut_state_t *state,
    int32_t id) {
  desktop_global_shortcut_registration_t *cursor = state->registrations;
  desktop_global_shortcut_registration_t *previous = NULL;
  while (cursor != NULL) {
    if (cursor->id == id) {
      if (previous == NULL) {
        state->registrations = cursor->next;
      } else {
        previous->next = cursor->next;
      }
      free(cursor->accelerator);
      free(cursor);
      return;
    }
    previous = cursor;
    cursor = cursor->next;
  }
}

static void desktop_global_shortcut_push_trigger(
    desktop_global_shortcut_state_t *state,
    int32_t id) {
  desktop_global_shortcut_trigger_t *node =
      (desktop_global_shortcut_trigger_t *)calloc(1, sizeof(*node));
  if (node == NULL) {
    return;
  }
  node->id = id;
  if (state->triggered_tail == NULL) {
    state->triggered_head = node;
    state->triggered_tail = node;
  } else {
    state->triggered_tail->next = node;
    state->triggered_tail = node;
  }
}

static DWORD WINAPI desktop_global_shortcut_thread_main(void *raw_state) {
  MSG message;
  desktop_global_shortcut_state_t *state =
      (desktop_global_shortcut_state_t *)raw_state;
  PeekMessage(&message, NULL, WM_USER, WM_USER, PM_NOREMOVE);
  SetEvent(state->ready_event);
  while (GetMessage(&message, NULL, 0, 0) > 0) {
    if (message.message == DESKTOP_GLOBAL_SHORTCUT_MSG_REGISTER) {
      desktop_global_shortcut_command_t *command =
          (desktop_global_shortcut_command_t *)message.lParam;
      if (RegisterHotKey(NULL, command->id, command->modifiers, command->key)) {
        desktop_global_shortcut_registration_t *registration =
            (desktop_global_shortcut_registration_t *)calloc(
                1, sizeof(desktop_global_shortcut_registration_t));
        if (registration != NULL) {
          registration->id = command->id;
          registration->accelerator = command->accelerator;
          EnterCriticalSection(&state->lock);
          registration->next = state->registrations;
          state->registrations = registration;
          LeaveCriticalSection(&state->lock);
          command->accelerator = NULL;
          command->success = 1;
        }
      }
      if (command->accelerator != NULL) {
        free(command->accelerator);
      }
      SetEvent(command->done_event);
      continue;
    }

    if (message.message == DESKTOP_GLOBAL_SHORTCUT_MSG_UNREGISTER) {
      desktop_global_shortcut_command_t *command =
          (desktop_global_shortcut_command_t *)message.lParam;
      command->success = UnregisterHotKey(NULL, command->id);
      EnterCriticalSection(&state->lock);
      desktop_global_shortcut_remove_registration(state, command->id);
      LeaveCriticalSection(&state->lock);
      SetEvent(command->done_event);
      continue;
    }

    if (message.message == DESKTOP_GLOBAL_SHORTCUT_MSG_QUIT) {
      PostQuitMessage(0);
      continue;
    }

    if (message.message == WM_HOTKEY) {
      EnterCriticalSection(&state->lock);
      desktop_global_shortcut_push_trigger(state, (int32_t)message.wParam);
      LeaveCriticalSection(&state->lock);
    }
  }

  EnterCriticalSection(&state->lock);
  {
    desktop_global_shortcut_registration_t *cursor = state->registrations;
    while (cursor != NULL) {
      UnregisterHotKey(NULL, cursor->id);
      cursor = cursor->next;
    }
    desktop_global_shortcut_free_registrations(state->registrations);
    state->registrations = NULL;
    desktop_global_shortcut_free_triggers(state->triggered_head);
    state->triggered_head = NULL;
    state->triggered_tail = NULL;
  }
  LeaveCriticalSection(&state->lock);
  return 0;
}
#endif

MOONBIT_FFI_EXPORT int32_t desktop_global_shortcut_is_windows(void) {
#ifdef _WIN32
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT desktop_global_shortcut_state_t *
desktop_global_shortcut_create(void) {
#ifdef _WIN32
  desktop_global_shortcut_state_t *state =
      (desktop_global_shortcut_state_t *)calloc(1, sizeof(*state));
  if (state == NULL) {
    return NULL;
  }
  state->ready_event = CreateEventW(NULL, TRUE, FALSE, NULL);
  if (state->ready_event == NULL) {
    free(state);
    return NULL;
  }
  InitializeCriticalSection(&state->lock);
  state->thread = CreateThread(NULL, 0, desktop_global_shortcut_thread_main,
                               state, 0, &state->thread_id);
  if (state->thread == NULL) {
    DeleteCriticalSection(&state->lock);
    CloseHandle(state->ready_event);
    free(state);
    return NULL;
  }
  WaitForSingleObject(state->ready_event, INFINITE);
  return state;
#else
  return NULL;
#endif
}

MOONBIT_FFI_EXPORT void desktop_global_shortcut_destroy(
    desktop_global_shortcut_state_t *state) {
#ifdef _WIN32
  if (state == NULL) {
    return;
  }
  PostThreadMessage(state->thread_id, DESKTOP_GLOBAL_SHORTCUT_MSG_QUIT, 0, 0);
  WaitForSingleObject(state->thread, INFINITE);
  DeleteCriticalSection(&state->lock);
  CloseHandle(state->thread);
  CloseHandle(state->ready_event);
  free(state);
#else
  (void)state;
#endif
}

MOONBIT_FFI_EXPORT int32_t desktop_global_shortcut_register(
    desktop_global_shortcut_state_t *state,
    int32_t id,
    int32_t modifiers,
    int32_t key,
    moonbit_bytes_t accelerator) {
#ifdef _WIN32
  desktop_global_shortcut_command_t command;
  if (state == NULL) {
    return 0;
  }
  memset(&command, 0, sizeof(command));
  command.done_event = CreateEventW(NULL, TRUE, FALSE, NULL);
  if (command.done_event == NULL) {
    return 0;
  }
  command.id = id;
  command.modifiers = modifiers;
  command.key = key;
  command.accelerator = desktop_global_shortcut_strdup((const char *)accelerator);
  if (command.accelerator == NULL) {
    CloseHandle(command.done_event);
    return 0;
  }
  if (!PostThreadMessage(state->thread_id, DESKTOP_GLOBAL_SHORTCUT_MSG_REGISTER, 0,
                         (LPARAM)&command)) {
    free(command.accelerator);
    CloseHandle(command.done_event);
    return 0;
  }
  WaitForSingleObject(command.done_event, INFINITE);
  CloseHandle(command.done_event);
  return command.success;
#else
  (void)state;
  (void)id;
  (void)modifiers;
  (void)key;
  (void)accelerator;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t desktop_global_shortcut_unregister(
    desktop_global_shortcut_state_t *state,
    int32_t id) {
#ifdef _WIN32
  desktop_global_shortcut_command_t command;
  if (state == NULL) {
    return 0;
  }
  memset(&command, 0, sizeof(command));
  command.done_event = CreateEventW(NULL, TRUE, FALSE, NULL);
  if (command.done_event == NULL) {
    return 0;
  }
  command.id = id;
  if (!PostThreadMessage(state->thread_id, DESKTOP_GLOBAL_SHORTCUT_MSG_UNREGISTER,
                         0, (LPARAM)&command)) {
    CloseHandle(command.done_event);
    return 0;
  }
  WaitForSingleObject(command.done_event, INFINITE);
  CloseHandle(command.done_event);
  return command.success;
#else
  (void)state;
  (void)id;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t desktop_global_shortcut_take_triggered_id(
    desktop_global_shortcut_state_t *state) {
#ifdef _WIN32
  int32_t id = 0;
  desktop_global_shortcut_trigger_t *node;
  if (state == NULL) {
    return 0;
  }
  EnterCriticalSection(&state->lock);
  node = state->triggered_head;
  if (node != NULL) {
    id = node->id;
    state->triggered_head = node->next;
    if (state->triggered_head == NULL) {
      state->triggered_tail = NULL;
    }
    free(node);
  }
  LeaveCriticalSection(&state->lock);
  return id;
#else
  (void)state;
  return 0;
#endif
}
