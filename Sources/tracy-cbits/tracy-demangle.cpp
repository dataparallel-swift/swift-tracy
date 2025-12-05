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
// This module provides swift name demangling for client display

#ifdef TRACY_ENABLE

#include <dlfcn.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <cxxabi.h>
#include "tracy/public/common/TracyAlloc.hpp"

constexpr size_t ___tracy_demangle_buffer_len = 1024*1024;
char* ___tracy_demangle_buffer;

extern "C" const char* ___tracy_demangle( const char* mangled )
{
  if ( !mangled )
    return nullptr;

  size_t mangled_len = strlen( mangled );
  if ( mangled_len > ___tracy_demangle_buffer_len )
    return nullptr;

  // Swift demangling
  if ( mangled[0] == '$' ) {
    static bool once = false;
    static char* (*swift_demangle)(const char*, size_t, char*, size_t*, uint32_t) = nullptr;

    if ( !once && !swift_demangle ) {
      once = true;
      *(void**) (&swift_demangle) = dlsym(RTLD_DEFAULT, "swift_demangle");
    }

    if ( !swift_demangle ) {
      return nullptr;
    }

    size_t len = ___tracy_demangle_buffer_len;
    return swift_demangle( mangled, mangled_len, ___tracy_demangle_buffer, &len, 0 );
  }
  // C++ demangling
  else if ( mangled[0] == '_' ) {
    int status;
    size_t len = ___tracy_demangle_buffer_len;
    return abi::__cxa_demangle( mangled, ___tracy_demangle_buffer, &len, &status );
  }

  return nullptr;
}

void ___tracy_init_demangle_buffer()
{
    ___tracy_demangle_buffer = (char*)tracy::tracy_malloc( ___tracy_demangle_buffer_len );
}

void ___tracy_free_demangle_buffer()
{
    tracy::tracy_free( ___tracy_demangle_buffer );
}

#endif
