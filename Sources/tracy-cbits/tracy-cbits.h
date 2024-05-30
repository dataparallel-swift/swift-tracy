/*
 * Interoperability layer to produce Tracy profiler traces from Swift
 */

#ifndef __TRACY_CBITS_H__
#define __TRACY_CBITS_H__

#define TRACY_ENABLE
#define TRACY_NO_FRAME_IMAGE

#include "tracy/public/tracy/TracyC.h"

#ifdef __cplusplus
extern "C" {
#endif

/* TRACY_API const struct ___tracy_source_location_data* __attribute__((returns_nonnull)) ___tracy_arena_alloc_srcloc( const char* name, const char* function, const char* file, uint32_t line, uint32_t colour ); */
/* TRACY_API void ___tracy_arena_free_srcloc( const struct ___tracy_source_location_data* __attribute__((nonnull)) loc ); */

#ifdef __cplusplus
}
#endif

#endif

