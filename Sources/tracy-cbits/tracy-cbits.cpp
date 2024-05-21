/*
 * Interoperability layer to produce Tracy profiler traces from Swift
 *
 * This module compiles the Tracy client so that it can be integrated with the
 * application. All applications then link against this library so that there is
 * only ever a single instance of the client collecting instrumentation data.
 */

#include "tracy-cbits.h"
#include "tracy/public/TracyClient.cpp"

