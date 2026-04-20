// An empty file. This is required because otherwise Swift tools 6.2+ will fail to
// compile when Tracy is disabled (SWIFT_TRACY_ENABLE=false), because:
//   - the TracyC target sources field will be empty; so
//   - the compiler will assume all sources in this directory need to be compiled; and
//   - it will find the profiler GUI main.cpp file; and
//   - therefore assumes TracyC should be an .executableTarget instead and fail
