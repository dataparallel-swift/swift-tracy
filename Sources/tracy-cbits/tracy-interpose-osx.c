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

// macOS malloc interposition for Tracy memory tracking.
//
// NOTE: This file is #include-d by tracy-interpose.c (the platform routing
// shim). It is NOT compiled as an independent translation unit by SPM.
//
// On macOS, __DATA,__interpose (dyld interposition) only works for dylibs, not
// for static libraries linked into the main executable. The malloc_zone_t zone
// registration approach works but only intercepts the default zone — not the
// nano allocator zone that handles small allocations on macOS 10.12+.
//
// The correct approach is malloc_logger: a function pointer in libmalloc that
// is called for every alloc/free across ALL zones (including nano), regardless
// of whether the library is static or dynamic. It is the same hook used by
// Instruments for memory profiling.
//
// Argument layout (malloc_logger is always called with MALLOC_LOG_TYPE_HAS_ZONE):
//   malloc(n):         type=ALLOC|HAS_ZONE,        arg1=zone, arg2=size,    result=ptr
//   free(ptr):         type=DEALLOC|HAS_ZONE,       arg1=zone, arg2=ptr,    result=0
//   realloc(old, n):   type=ALLOC|DEALLOC|HAS_ZONE, arg1=zone, arg2=old_ptr, arg3=new_size, result=new_ptr
//   calloc(cnt, n):    type=ALLOC|CLEARED|HAS_ZONE, arg1=zone, arg2=cnt*n,  result=ptr
//
// A per-thread reentrancy guard prevents Tracy's own internal malloc/free calls
// from being re-intercepted, which would cause infinite recursion.

#ifdef TRACY_ENABLE

#include "tracy/public/tracy/TracyC.h"

#include <malloc/malloc.h>
#include <pthread.h>
#include <stdint.h>

// malloc_logger is a libmalloc private API used by Instruments for memory
// profiling. It is not declared in the public SDK headers but has been stable
// since macOS 10.6. Declaring it here avoids a dependency on private headers.
typedef void (malloc_logger_t)(uint32_t type, uintptr_t arg1, uintptr_t arg2,
                               uintptr_t arg3, uintptr_t result,
                               uint32_t num_hot_frames_to_skip);
extern malloc_logger_t* malloc_logger;

// Bit flags used by libmalloc when calling malloc_logger.
// These values are stable across macOS versions (used by Instruments, heapshot, etc.)
#define TRACY_MALLOC_LOG_TYPE_ALLOC   2
#define TRACY_MALLOC_LOG_TYPE_DEALLOC 4

// Per-thread reentrancy guard using a POSIX key.
//
// We cannot use `__thread` (TLS) here because accessing TLS from within a
// malloc_logger callback is unsafe: the TLS runtime may itself call malloc,
// causing a deadlock or crash. pthread_getspecific/setspecific stores values
// in a pre-allocated slot in the thread structure and never calls malloc.
static pthread_key_t ___tracy_busy_key;
static malloc_logger_t* ___tracy_prev_malloc_logger;

static void ___tracy_malloc_logger(
    uint32_t  type,
    uintptr_t arg1,    // zone pointer (always present; unused here)
    uintptr_t arg2,    // alloc: size; dealloc: freed ptr; realloc: old ptr
    uintptr_t arg3,    // realloc: new size; else 0
    uintptr_t result,  // alloc/realloc: new ptr; dealloc: 0
    uint32_t  skip)
{
    (void)arg1; (void)skip;

    if (!TracyCIsStarted || pthread_getspecific(___tracy_busy_key))
        return;

    pthread_setspecific(___tracy_busy_key, (void*)1);

    const int is_alloc   = (type & TRACY_MALLOC_LOG_TYPE_ALLOC)   != 0;
    const int is_dealloc = (type & TRACY_MALLOC_LOG_TYPE_DEALLOC) != 0;

    // For realloc, arg2 is the old pointer and arg3 is the new size.
    // For a plain free, arg2 is the freed pointer.
    if (is_dealloc && arg2) {
        TracyCFree((void*)arg2);
    }

    // For realloc, the new size is in arg3. For malloc/calloc, it is in arg2.
    if (is_alloc && result) {
        const size_t size = is_dealloc ? (size_t)arg3 : (size_t)arg2;
        TracyCAlloc((void*)result, size);
    }

    pthread_setspecific(___tracy_busy_key, (void*)0);
}

void ___tracy_init_malloc_logger(void)
{
    pthread_key_create(&___tracy_busy_key, NULL);
    ___tracy_prev_malloc_logger = malloc_logger;
    malloc_logger = ___tracy_malloc_logger;
}

void ___tracy_deinit_malloc_logger(void)
{
    if (malloc_logger == ___tracy_malloc_logger)
        malloc_logger = ___tracy_prev_malloc_logger;
    pthread_key_delete(___tracy_busy_key);
}

#endif  // TRACY_ENABLE
