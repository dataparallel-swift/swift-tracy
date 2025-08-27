/*
 * Interoperability layer to produce Tracy profiler traces from Swift
 *
 * This module adds overrides to the standard memory allocation functions,
 * allowing for memory tracking in the profiler.
 */

#ifdef TRACY_ENABLE

#define _GNU_SOURCE // required for RTLD_NEXT

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
// #include "tracy/public/tracy/Tracy.hpp"

#include <assert.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>

#if defined(__GNUC__) || defined(__clang__)
#define tracy_unlikely(x)     (__builtin_expect(!!(x),false))
#define tracy_likely(x)       (__builtin_expect(!!(x),true))
#elif (defined(__cplusplus) && (__cplusplus >= 202002L)) || (defined(_MSVC_LANG) && _MSVC_LANG >= 202002L)
#define tracy_unlikely(x)     (x) [[unlikely]]
#define tracy_likely(x)       (x) [[likely]]
#else
#define tracy_unlikely(x)     (x)
#define tracy_likely(x)       (x)
#endif

#if defined(__GNUC__) || defined(__clang__)
#endif



static void* tracy_malloc(size_t size)
{
  static void* (*next)(size_t) = NULL;
  if tracy_unlikely(!next) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "malloc");
    assert(next != NULL);
    assert(next != &tracy_malloc);
  }

  void* ptr = next(size);
  if (ptr == NULL)
    return NULL;

  if tracy_likely(TracyCIsStarted) {
    TracyCAlloc(ptr, size);
  }

  return ptr;
}

static void* tracy_calloc(size_t count, size_t size)
{
  static void* (*next)(size_t, size_t) = NULL;
  if tracy_unlikely(!next) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "calloc");
    assert(next != NULL);
    assert(next != &tracy_calloc);
  }

  void* ptr = next(count, size);
  if (ptr == NULL)
    return NULL;

  if tracy_likely(TracyCIsStarted) {
    TracyCAlloc(ptr, count * size);
  }

  return ptr;
}

static void* tracy_realloc(void* ptr, size_t new_size)
{
  static void* (*next)(void*, size_t) = NULL;
  if tracy_unlikely(!next) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "realloc");
    assert(next != NULL);
    assert(next != &tracy_realloc);
  }

  if tracy_likely(TracyCIsStarted) {
    TracyCFree(ptr);
  }

  void* new_ptr = next(ptr, new_size);
  if (new_ptr == NULL)
    return NULL;

  if tracy_likely(TracyCIsStarted) {
    TracyCAlloc(new_ptr, new_size);
  }

  return new_ptr;
}

// void* tracy_reallocf(void* ptr, size_t size)
// {
// }

static void tracy_free(void *ptr)
{
  static void (*next)(void*) = NULL;
  if tracy_unlikely(next == NULL) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "free");
    assert(next != NULL);
    assert(next != &tracy_free);
  }

  if tracy_likely(TracyCIsStarted) {
    TracyCFree(ptr);
  }

  next(ptr);
}

// void* tracy_valloc(size_t size)
// {
// }

// void tracy_vfree(void* ptr)
// {
// }

// void tracy_cfree(void* ptr)
// {
// }

static void* tracy__aligned_alloc(size_t alignment, size_t size)
{
  static void* (*next)(size_t, size_t) = NULL;
  if tracy_unlikely(next == NULL) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "_aligned_alloc");
    assert(next != NULL);
    assert(next != &tracy__aligned_alloc);
  }

  void* ptr = next(alignment, size);
  if (ptr == NULL)
    return NULL;

  if tracy_likely(TracyCIsStarted) {
    TracyCAlloc(ptr, size);
  }

  return ptr;
}

static void* tracy_memalign(size_t alignment, size_t size)
{
  static void* (*next)(size_t, size_t) = NULL;
  if tracy_unlikely(next == NULL) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "memalign");
    assert(next != NULL);
    assert(next != &tracy_memalign);
  }

  void* ptr = next(alignment, size);
  if (ptr == NULL)
    return NULL;

  if tracy_likely(TracyCIsStarted) {
    TracyCAlloc(ptr, size);
  }

  return ptr;
}

static int tracy_posix_memalign(void** ptr, size_t alignment, size_t size)
{
  static int (*next)(void**, size_t, size_t) = NULL;
  if tracy_unlikely(next == NULL) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "posix_memalign");
    assert(next != NULL);
    assert(next != &tracy_posix_memalign);
  }

  int result = next(ptr, alignment, size);
  if (result != 0)
    return result;

  if tracy_likely(TracyCIsStarted) {
    TracyCAlloc(*ptr, size);
  }

  return result;
}

#if !defined(__GLIBC__) || __USE_ISOC11
static void* tracy_aligned_alloc(size_t alignment, size_t size)
{
  static void* (*next)(size_t, size_t) = NULL;
  if tracy_unlikely(next == NULL) {
    *(void**) (&next) = dlsym(RTLD_NEXT, "aligned_alloc");
    assert(next != NULL);
    assert(next != &tracy_aligned_alloc);
  }

  void* ptr = next(alignment, size);
  if (ptr == NULL)
    return NULL;

  if tracy_likely(TracyCIsStarted) {
    TracyCAlloc(ptr, size);
  }

  return ptr;
}
#endif

#if (defined(__GNUC__) || defined(__clang__)) && !defined(__APPLE__)
  // gcc, clang: use aliasing to alias the exported function to one of our `tracy_` functions
  #if (defined(__GNUC__) && __GNUC__ >= 9)
    #pragma GCC diagnostic ignored "-Wattributes"  // or we get warnings that nodiscard is ignored on a forward
    #define TRACY_FORWARD(fun)      __attribute__((alias(#fun), used, visibility("default"), copy(fun)));
  #else
    #define TRACY_FORWARD(fun)      __attribute__((alias(#fun), used, visibility("default")));
  #endif
  #define TRACY_FORWARD1(fun,x)      TRACY_FORWARD(fun)
  #define TRACY_FORWARD2(fun,x,y)    TRACY_FORWARD(fun)
  #define TRACY_FORWARD3(fun,x,y,z)  TRACY_FORWARD(fun)
  #define TRACY_FORWARD0(fun,x)      TRACY_FORWARD(fun)
  #define TRACY_FORWARD02(fun,x,y)   TRACY_FORWARD(fun)
#else
  // otherwise use forwarding by calling our `tracy_` function
  #define TRACY_FORWARD1(fun,x)      { return fun(x); }
  #define TRACY_FORWARD2(fun,x,y)    { return fun(x,y); }
  #define TRACY_FORWARD3(fun,x,y,z)  { return fun(x,y,z); }
  #define TRACY_FORWARD0(fun,x)      { fun(x); }
  #define TRACY_FORWARD02(fun,x,y)   { fun(x,y); }
#endif

void* malloc(size_t size)                                       TRACY_FORWARD1(tracy_malloc, size)
void* calloc(size_t size, size_t n)                             TRACY_FORWARD2(tracy_calloc, size, n)
void* realloc(void* ptr, size_t new_size)                       TRACY_FORWARD2(tracy_realloc, ptr, new_size)
void  free(void* p)                                             TRACY_FORWARD0(tracy_free, p)
void* _aligned_alloc(size_t alignment, size_t size)             TRACY_FORWARD2(tracy__aligned_alloc, alignment, size)
void* memalign(size_t alignment, size_t size)                   TRACY_FORWARD2(tracy_memalign, alignment, size)
int   posix_memalign(void** ptr, size_t alignment, size_t size) TRACY_FORWARD3(tracy_posix_memalign, ptr, alignment, size)

#if !defined(__GLIBC__) || __USE_ISOC11
void* aligned_alloc(size_t alignment, size_t size)              TRACY_FORWARD2(tracy_aligned_alloc, alignment, size)
#endif

#if (defined(__GNUC__) || defined(__clang__)) && !defined(__APPLE__)
#pragma GCC visibility push(default)
#endif

#endif  // TRACY_ENABLE

