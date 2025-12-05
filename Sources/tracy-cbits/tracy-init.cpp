// Copyright (c) 2025 The swift-tracy authors. All rights reserved.
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

// Interoperability layer to produce Tracy profiler traces from Swift
//
// This module adds necessary initialisation routines.

#ifdef TRACY_ENABLE
#include "tracy/public/tracy/Tracy.hpp"

#ifdef TRACY_CUDA_ENABLE
#include <cuda.h>
#if CUDA_VERSION < 13000
#define CUpti_ActivityCudaEvent2 CUpti_ActivityCudaEvent
#endif

#include "tracy/public/tracy/TracyCUDA.hpp"
#endif

static void ___tracy_auto_process_init(void);
static void ___tracy_auto_process_done(void);

#if defined(__GNUC__) || defined(__clang__)
  // gcc,clang: use the constructor/destructor attribute
  // which for both seem to run before regular constructors/destructors
  #if defined(__clang__)
    #define tracy_attr_constructor __attribute__((constructor(101)))  // highest priority
    #define tracy_attr_destructor  __attribute__((destructor(101)))
  #else
    #define tracy_attr_constructor __attribute__((constructor))
    #define tracy_attr_destructor  __attribute__((destructor))
  #endif
  static void tracy_attr_constructor ___tracy_process_attach(void) {
    ___tracy_auto_process_init();
  }
  static void tracy_attr_destructor ___tracy_process_detach(void) {
    ___tracy_auto_process_done();
  }
#elif defined(__cplusplus)
  // C++: use static initialization to detect process start/end
  // This is not guaranteed to be first/last but the best we can generally do?
  struct ___tracy_init_done_t {
    ___tracy_init_done_t() {
      ___tracy_auto_process_init();
    }
    ~___tracy_init_done_t() {
      ___tracy_auto_process_done();
    }
  };
  static ___tracy_init_done_t ___tracy_init_done;
 #else
  #pragma message("define a way to call ___tracy_auto_process_init/done on your platform")
#endif


#if defined(TRACY_CUDA_ENABLE)
static tracy::CUDACtx* ___tracy_cuda_context = nullptr;
#endif

static void ___tracy_auto_process_init(void)
{
#if defined(TRACY_MANUAL_LIFETIME) && defined(TRACY_DELAYED_INIT)
  tracy::StartupProfiler();
#endif

#if defined(TRACY_CUDA_ENABLE)
  ___tracy_cuda_context = TracyCUDAContext();
  TracyCUDAStartProfiling(___tracy_cuda_context);
#endif
}

static void ___tracy_auto_process_done(void)
{
#if defined(TRACY_CUDA_ENABLE)
  TracyCUDAStopProfiling(___tracy_cuda_context);
  TracyCUDAContextDestroy(___tracy_cuda_context);
#endif

#if defined(TRACY_MANUAL_LIFETIME) && defined(TRACY_DELAYED_INIT)
  tracy::ShutdownProfiler();
#endif
}

#endif
