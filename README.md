# swift-tracy

Swift integration for the Tracy profiler, a real-time, nanosecond-resolution,
remote telemetry, hybrid instrumentation and sampling profiler with a
full-featured graphical interface for finding hot spots in profiled programs.

https://github.com/wolfpld/tracy

> [!IMPORTANT]
> Depending on the configuration, Tracy may broadcast discovery packets to the
> local network and expose the data it collects in the background to the same
> network. Collected traces may include source and assembly code as well.

## Adding it to your project

```swift
    dependencies: [
        .package(url: "https://github.com/dataparallel-swift/swift-tracy.git", from: "1.0.0")
    ]
```

By default, profiling is _not_ enabled. In order to enable profiling in client
applications this package needs to be built with the environment variable
`SWIFT_TRACY_ENABLE` set. Optionally, you may also set `SWIFT_TRACY_CUDA_ENABLE`
to enable CUDA profiling as well.

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

Similarly, there are functions for adding `message` and `Frame` data to the
trace.

## Docker on Linux

The best way to run Tracy is on bare metal. However, it is possible to run in a
containerised environment while retaining CPU sampling features if you grant
elevated access rights to the container running your client. For example:

```
docker run --rm -it --privileged --mount "type=bind,source=/sys/kernel/debug,target=/sys/kernel/debug,readonly" --user=0:0 --pid=host --runtime=nvidia --gpus=all ghcr.io/dataparallel-swift/swift:latest
```

## TODO

* Memory profiling on macOS
* Add #ZoneScoped macro (apple/swift#73707)
* Call directly into C++ API
