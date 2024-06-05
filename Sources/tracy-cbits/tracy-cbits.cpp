/*
 * Interoperability layer to produce Tracy profiler traces from Swift
 *
 * This module compiles the Tracy client so that it can be integrated with the
 * application. All applications then link against this library so that there is
 * only ever a single instance of the client collecting instrumentation data.
 */

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
#include "tracy/public/TracyClient.cpp"

