// Copyright (c) 2026 The swift-tracy authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Linux malloc interposition for Tracy memory tracking.
//
// NOTE: This file is #include-d by tracy-interpose.c (the platform routing
// shim). It is NOT compiled as an independent translation unit by SPM.
//
// On Linux/ELF, we export our wrapper functions under the standard allocator
// symbol names using GCC/Clang alias attributes (or direct definitions as a
// fallback). The dynamic linker resolves calls to malloc/free/etc. to our
// wrappers process-wide. RTLD_NEXT is used to reach the real allocator.

#ifdef TRACY_ENABLE

#ifndef _GNU_SOURCE
#define _GNU_SOURCE // required for RTLD_NEXT
#endif

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

#include <assert.h>
#include <dlfcn.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <malloc.h>

#if defined(__GNUC__) || defined(__clang__)
#define TRACY_UNLIKELY(x)     (__builtin_expect(!!(x),false))
#define TRACY_LIKELY(x)       (__builtin_expect(!!(x),true))
#else
#define TRACY_UNLIKELY(x)     (x)
#define TRACY_LIKELY(x)       (x)
#endif

#define DLSYM_REAL(NAME) \
  static __typeof__(NAME)* real_##NAME = NULL; \
  if TRACY_UNLIKELY(!real_##NAME) { \
    *(void**) &real_##NAME = dlsym(RTLD_NEXT, #NAME); \
    assert(real_##NAME  != NULL && "dlsym failed"); \
  }


static void* tracy_malloc(size_t size)
{
  DLSYM_REAL(malloc);

  void* ptr = real_malloc(size);
  if (ptr == NULL)
    return NULL;

  if TRACY_LIKELY(TracyCIsStarted) {
    TracyCAlloc(ptr, size);
  }

  return ptr;
}

static void* tracy_calloc(size_t count, size_t size)
{
  DLSYM_REAL(calloc);

  void* ptr = real_calloc(count, size);
  if (ptr == NULL)
    return NULL;

  if TRACY_LIKELY(TracyCIsStarted) {
    TracyCAlloc(ptr, count * size);
  }

  return ptr;
}

static void tracy_free(void *ptr)
{
  DLSYM_REAL(free);

  // free(NULL) is a no-op; don't emit a spurious TracyCFree at address 0.
  if (ptr != NULL && TracyCIsStarted) {
    TracyCFree(ptr);
  }

  real_free(ptr);
}

static void* tracy_realloc(void* ptr, size_t new_size)
{
  DLSYM_REAL(realloc);

  // realloc(ptr, 0) is defined as free(ptr) on glibc; handle it explicitly so
  // we always emit a TracyCFree and don't mistake the NULL return for OOM.
  if (new_size == 0) {
    tracy_free(ptr);
    return NULL;
  }

  void* new_ptr = real_realloc(ptr, new_size);
  if (new_ptr == NULL)
    return NULL;  // OOM — ptr is still valid and still tracked

  if TRACY_LIKELY(TracyCIsStarted) {
    TracyCFree(ptr);
    TracyCAlloc(new_ptr, new_size);
  }

  return new_ptr;
}

static void* tracy_memalign(size_t alignment, size_t size)
{
  DLSYM_REAL(memalign);

  void* ptr = real_memalign(alignment, size);
  if (ptr == NULL)
    return NULL;

  if TRACY_LIKELY(TracyCIsStarted) {
    TracyCAlloc(ptr, size);
  }

  return ptr;
}

static int tracy_posix_memalign(void** ptr, size_t alignment, size_t size)
{
  DLSYM_REAL(posix_memalign);

  int result = real_posix_memalign(ptr, alignment, size);
  if (result != 0)
    return result;

  if TRACY_LIKELY(TracyCIsStarted) {
    TracyCAlloc(*ptr, size);
  }

  return result;
}

#if !defined(__GLIBC__) || __USE_ISOC11
static void* tracy_aligned_alloc(size_t alignment, size_t size)
{
  DLSYM_REAL(aligned_alloc);

  void* ptr = real_aligned_alloc(alignment, size);
  if (ptr == NULL)
    return NULL;

  if TRACY_LIKELY(TracyCIsStarted) {
    TracyCAlloc(ptr, size);
  }

  return ptr;
}
#endif

// On Linux/ELF, use GCC/Clang alias attributes to export our wrappers under
// the standard allocator names, or fall back to direct symbol definitions.
#if (defined(__GNUC__) || defined(__clang__))
  #if (defined(__GNUC__) && __GNUC__ >= 9)
    #pragma GCC diagnostic ignored "-Wattributes"  // nodiscard warning on forward
    #define TRACY_FORWARD(fun)      __attribute__((alias(#fun), used, visibility("default"), copy(fun)));
  #else
    #define TRACY_FORWARD(fun)      __attribute__((alias(#fun), used, visibility("default")));
  #endif
  #define TRACY_FORWARD1(fun,x)      TRACY_FORWARD(fun)
  #define TRACY_FORWARD2(fun,x,y)    TRACY_FORWARD(fun)
  #define TRACY_FORWARD3(fun,x,y,z)  TRACY_FORWARD(fun)
  #define TRACY_FORWARD0(fun,x)      TRACY_FORWARD(fun)
#else
  #define TRACY_FORWARD1(fun,x)      { return fun(x); }
  #define TRACY_FORWARD2(fun,x,y)    { return fun(x,y); }
  #define TRACY_FORWARD3(fun,x,y,z)  { return fun(x,y,z); }
  #define TRACY_FORWARD0(fun,x)      { fun(x); }
#endif

void* malloc(size_t size)                                       TRACY_FORWARD1(tracy_malloc, size)
void* calloc(size_t count, size_t size)                         TRACY_FORWARD2(tracy_calloc, count, size)
void* realloc(void* ptr, size_t new_size)                       TRACY_FORWARD2(tracy_realloc, ptr, new_size)
void  free(void* p)                                             TRACY_FORWARD0(tracy_free, p)
int   posix_memalign(void** ptr, size_t alignment, size_t size) TRACY_FORWARD3(tracy_posix_memalign, ptr, alignment, size)
void* memalign(size_t alignment, size_t size)                   TRACY_FORWARD2(tracy_memalign, alignment, size)
#if !defined(__GLIBC__) || __USE_ISOC11
void* aligned_alloc(size_t alignment, size_t size)              TRACY_FORWARD2(tracy_aligned_alloc, alignment, size)
#endif

#endif  // TRACY_ENABLE
