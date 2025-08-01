/*
 * Interoperability layer to produce Tracy profiler traces from Swift
 *
 * This module compiles the Tracy client so that it can be integrated with the
 * application. All applications then link against this library so that there is
 * only ever a single instance of the client collecting instrumentation data.
 */

#ifdef TRACY_ENABLE

// Not including our custom header because SPM is not applying preprocessor
// defines when including the header only (so we need to #define TRACY_ENABLE
// directly in that file, which causes a redefinition warning when it is
// encountered through the include here); and because we need to change the type
// of the source location struct in order to appease the Swift/C++ interop.
//
// This means that the API presented to the C++ compiler and the Swift compiler
// are actually different, so we need to make sure that they are kept in sync
// (modulo our type changes which don't otherwise affect anything).

/* #include "tracy-cbits.h" */

#include "tracy/public/tracy/TracyC.h"
#include "tracy/public/tracy/Tracy.hpp"
#include "tracy/public/TracyClient.cpp"

#include <stdint.h>

#if __has_builtin(__builtin_expect)
#define TRACY_LIKELY(expression) (__builtin_expect(!!(expression), 1))
#define TRACY_UNLIKELY(expression) (__builtin_expect(!!(expression), 0))
#else
#define TRACY_LIKELY(expression) ((expression))
#define TRACY_UNLIKELY(expression) ((expression))
#endif

__attribute__((constructor))
void tracy_init() {
  tracy::StartupProfiler();
}


#ifdef TRACY_INTERPOSE
#ifdef __cplusplus
extern "C" {
#endif

// This seems to work on *nix with glibc but will probably break elsewhere
void* __libc_malloc(size_t size);
void* __libc_calloc(size_t count, size_t size);
void* __libc_realloc(void* ptr, size_t size);
void* __libc_memalign(size_t alignment, size_t size);
void  __libc_free(void* ptr);

#ifdef __cplusplus
}
#endif

void* malloc(size_t size)
{
  void* ptr = __libc_malloc(size);

  if (TRACY_LIKELY(TracyIsStarted)) {
    TracyAlloc(ptr, size);
  }

  return ptr;
}

void* calloc(size_t count, size_t size)
{
  void* ptr = __libc_calloc(count, size);

  if (TRACY_LIKELY(TracyIsStarted)) {
    TracyAlloc(ptr, count * size);
  }

  return ptr;
}

void* realloc(void* ptr, size_t size)
{
  void* new_ptr = __libc_realloc(ptr, size);

  if (TRACY_LIKELY(TracyIsStarted)) {
    TracyFree(ptr);
    TracyAlloc(new_ptr, size);
  }

  return new_ptr;
}

void* memalign(size_t alignment, size_t size)
{
  void* ptr = __libc_memalign(alignment, size);

  if (TRACY_LIKELY(TracyIsStarted)) {
    TracyAlloc(ptr, size);
  }

  return ptr;
}

void free(void* ptr)
{
  __libc_free(ptr);

  if (TRACY_LIKELY(TracyIsStarted)) {
    TracyFree(ptr);
  }
}

#endif  // TRACY_INTERPOSE
#endif  // TRACY_ENABLE

