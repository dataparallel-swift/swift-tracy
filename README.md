# swift-tracy

Swift integration for the Tracy profiler, a real-time, nanosecond-resolution,
remote telemetry, hybrid instrumentation and sampling profiler with a
full-featured graphical interface for finding hot spots in profiled programs.

https://github.com/wolfpld/tracy

## Important note

Depending on the configuration, Tracy may broadcast discovery packets to the
local network and expose the data it collects in the background to the same
network. Collected traces may include source and assembly code as well.

## Adding it to your project

```swift
    dependencies: [
        .package(url: "git@gitlab.com:PassiveLogic/Experiments/swift-tracy", revision: "...")
    ]
```

## Adding it to your code

Unless your application is able to perform automated call stack sampling
(platform dependent) you will need to manually mark up the application code in
order to collect any trace data.

Manual instrumentation is best started by adding markup to the application's
main loop and a few functions that it calls, in order to get a rough outline of
the function's time cost, and refining the instrumentation deeper into the call
stack from there. Automated sampling might also help guide you towards places of
interest.

```swift
import Tracy

func foo() {
    let z = #Zone
    defer { z.end() }

    // ... rest of the code
}
```

The `#Zone` macro optionally takes arguments to specify a custom name, colour,
and callstack depth. It can also be set as active or disabled.

If you cannot use the `#Zone` macro, the `Zone` struct initialiser can be used
instead, which takes the same arguments and is used in the same way, but has a
higher runtime overhead.

## TODO

* Add SPM configuration option to globally enable/disable tracing
* Add #ZoneScoped macro (apple/swift#73707)
* Call directly into C++ API

