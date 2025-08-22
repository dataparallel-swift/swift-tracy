/*
 * Interoperability layer to produce Tracy profiler traces from Swift
 */

#ifndef __TRACY_CBITS_H__
#define __TRACY_CBITS_H__

// Not including directly because SPM does not apply pre-processor defines when
// including header files only, and we also need to change the type of the
// source location data to appease Swift/C++ interop.

/* #include "tracy/public/tracy/TracyC.h" */

#include <stddef.h>
#include <stdint.h>

#include "tracy/public/client/TracyCallstack.h"
#include "tracy/public/common/TracyApi.h"

#ifdef __cplusplus
extern "C" {
#endif

struct ___tracy_source_location_data
{
    const uint8_t* name;        // XXX: char -> uint8_t
    const uint8_t* function;    // XXX: char -> uint8_t
    const uint8_t* file;        // XXX: char -> uint8_t
    uint32_t line;
    uint32_t color;
};

struct ___tracy_c_zone_context
{
    uint32_t id;
    int active;
};

// Some containers don't support storing const types.
// This struct, as visible to user, is immutable, so treat it as if const was declared here.
typedef /*const*/ struct ___tracy_c_zone_context TracyCZoneCtx;

TRACY_API uint64_t ___tracy_alloc_srcloc( uint32_t line, const char* source, size_t sourceSz, const char* function, size_t functionSz, uint32_t color );
TRACY_API uint64_t ___tracy_alloc_srcloc_name( uint32_t line, const char* source, size_t sourceSz, const char* function, size_t functionSz, const char* name, size_t nameSz, uint32_t color );

TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin( const struct ___tracy_source_location_data* srcloc, int active );
TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin_callstack( const struct ___tracy_source_location_data* srcloc, int depth, int active );
TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin_alloc( uint64_t srcloc, int active );
TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin_alloc_callstack( uint64_t srcloc, int depth, int active );
TRACY_API void ___tracy_emit_zone_end( TracyCZoneCtx ctx );
TRACY_API void ___tracy_emit_zone_text( TracyCZoneCtx ctx, const char* txt, size_t size );
TRACY_API void ___tracy_emit_zone_name( TracyCZoneCtx ctx, const char* txt, size_t size );
TRACY_API void ___tracy_emit_zone_color( TracyCZoneCtx ctx, uint32_t color );
TRACY_API void ___tracy_emit_zone_value( TracyCZoneCtx ctx, uint64_t value );

TRACY_API void ___tracy_emit_memory_alloc( const void* ptr, size_t size, int secure );
TRACY_API void ___tracy_emit_memory_alloc_callstack( const void* ptr, size_t size, int depth, int secure );
TRACY_API void ___tracy_emit_memory_free( const void* ptr, int secure );
TRACY_API void ___tracy_emit_memory_free_callstack( const void* ptr, int depth, int secure );
TRACY_API void ___tracy_emit_memory_alloc_named( const void* ptr, size_t size, int secure, const char* name );
TRACY_API void ___tracy_emit_memory_alloc_callstack_named( const void* ptr, size_t size, int depth, int secure, const char* name );
TRACY_API void ___tracy_emit_memory_free_named( const void* ptr, int secure, const char* name );
TRACY_API void ___tracy_emit_memory_free_callstack_named( const void* ptr, int depth, int secure, const char* name );

TRACY_API void ___tracy_emit_message( const char* txt, size_t size, int callstack );
TRACY_API void ___tracy_emit_messageL( const char* txt, int callstack );
TRACY_API void ___tracy_emit_messageC( const char* txt, size_t size, uint32_t color, int callstack );
TRACY_API void ___tracy_emit_messageLC( const char* txt, uint32_t color, int callstack );

TRACY_API void ___tracy_emit_frame_mark( const char* name );

TRACY_API void ___tracy_emit_message_appinfo( const char* txt, size_t size );

#ifdef TRACY_MANUAL_LIFETIME
TRACY_API void ___tracy_startup_profiler(void);
TRACY_API void ___tracy_shutdown_profiler(void);
TRACY_API int32_t ___tracy_profiler_started(void);

#  define TracyCIsStarted ___tracy_profiler_started()
#else
#  define TracyCIsStarted 1
#endif

#ifdef __cplusplus
}
#endif

#endif

