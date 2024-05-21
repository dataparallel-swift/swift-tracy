
@_exported import TracyC

// A zone represents some period you want to record in the profiler. Typically
// this is used to measure the duration of a whole scope of a profiled function,
// but can also be used to measure time spent in the scopes of a for-loop or
// if-branch.
//
// To record a zone's execution time, add this macro at the beginning of the
// scope that you want to measure. It will automatically record the function
// name, and the source file name and location.
//
// The macro can optionally take 'name:' and 'colour:' parameters, to set a
// custom colour and name for the zone. The call stack can also be collected
// with the zone by specifying the 'callstack:' parameter, which specifies the
// depth of the callstack to capture. See the Tracy manual for further
// information regarding callstack collection.zone
//
@freestanding(codeItem)
public macro ZoneScoped(name: StaticString = .init(), colour: UInt32 = 0, callstack: Int32 = 0) =
    #externalMacro(module: "TracyMacros", type: "ZoneScoped")

