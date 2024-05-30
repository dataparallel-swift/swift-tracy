/*
 * Interoperability layer to produce Tracy profiler traces from Swift
 *
 * This module compiles the Tracy client so that it can be integrated with the
 * application. All applications then link against this library so that there is
 * only ever a single instance of the client collecting instrumentation data.
 */

#include "tracy-cbits.h"
#include "tracy/public/TracyClient.cpp"

#if 0
/* Because Swift:
 *   1. Does not follow lexical lifetime rules for the struct as a whole i.e.
 *      freeing storage for individual struct members as soon as it determines
 *      that value is no longer used; and
 *   2. Insists on copying data around needlessly, because the _address_ of a
 *      value is irrelevant in Swift
 *
 * Then from the Swift side we would need to use the _alloc versions of the
 * Tracy API functions. In order to work around this, we create our own stack
 * (i.e. arena allocator) and store the source location data there.
 *
 * XXX: This doesn't work because we cannot reuse source location structs; each
 * must be a _static_ data structure unique to a source location that is
 * embedded in the program code, so the profiler thread can access it at any
 * time during program execution. What we would need to do is be able to return
 * the same address for a given name/function/file/line/color combination.
 *
 * TODO: We might be able to use a macro to embed the source_location_data
 * struct as binary data (maybe as a StaticString) in the executable. Might be
 * tricky to convince the compiler to keep the #file and #function data around,
 * and to get the pointer address of it. Just reserving enough space for the
 * source location data might be enough (a StaticString filled with some random
 * data, so that it does not get interned), although we want to be sure to
 * initialise it only once.
 */

#define CACHE_SIZE 64
#define SINGLE_CACHE_ALIGN __attribute__((aligned(1 * CACHE_SIZE)))
#define DOUBLE_CACHE_ALIGN __attribute__((aligned(2 * CACHE_SIZE)))

// Maximum stack depth; what is a reasonable value here?
#define ARENA_SIZE 128

static thread_local uint32_t ___arena_next /* DOUBLE_CACHE_ALIGN */ = 0;
static thread_local struct ___tracy_source_location_data ___arena[ARENA_SIZE] = { 0 };

TRACY_API const struct ___tracy_source_location_data* __attribute__((returns_nonnull)) ___tracy_arena_alloc_srcloc( const char* name, const char* function, const char* file, uint32_t line, uint32_t colour )
{
  uint32_t idx = ___arena_next++;
  assert(idx < ARENA_SIZE && "arena overflow");

  struct ___tracy_source_location_data* loc = &___arena[idx];

  loc->name = name;
  loc->function = function;
  loc->file = file;
  loc->line = line;
  loc->color = colour;

  return loc;
}

TRACY_API void ___tracy_arena_free_srcloc( const struct ___tracy_source_location_data* __attribute__((nonnull)) loc )
{
  ___arena_next--;
  assert(loc == &___arena[___arena_next] && "mismatched arena alloc/free");
}
#endif

