
import TracyC

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
// NOTE: Currently does not work due to https://github.com/apple/swift/issues/73707
//
// @freestanding(codeItem)
// public macro ZoneScoped(name: StaticString = .init(), colour: UInt32 = 0, callstack: Int32 = 0) =
//     #externalMacro(module: "TracyMacros", type: "ZoneScoped")


// A zone represents some period you want to record in the profiler. Typically
// this is used to measure the duration of a whole scope of a profiled function,
// but can also be used to measure time spent in the scopes of a for-loop or
// if-branch.
//
// To record a zone's execution time, create this struct at the beginning of the
// scope that you want to measure. As there is no automatic destruction
// mechanism, you must manually mark where the zone ends.
//
public struct Zone {
    @usableFromInline
    let ctx : TracyCZoneCtx

    // Swift does not allow us to store variables on the stack in the same way
    // as in C (that is; unmoving, lexically scoped). I have attempted to work
    // around that by keeping our own (thread local) stack (i.e. arena
    // allocator) for the source location data and interact with the C API via
    // that, but source location zones are identified using _static_ data
    // structures that are embedded in the program code, because the profiler
    // (background thread) may need to access that data at any time during the
    // program lifetime. Thus we cannot reuse source location structures.
    //
    // Thus we are forced to use the _alloc versions of the functions which copy
    // the source location data into an on-heap buffer. This has (significant)
    // performance implications, but there is no easy way around it.
    @inlinable
    @inline(__always)
    public init(name: StaticString? = nil, function: StaticString = #function, file: StaticString = #file, line: UInt32 = #line, colour: UInt32 = 0, callstack: Int32 = 0, active: Bool = true) {
        let loc = ___tracy_alloc_srcloc_name(line, file.utf8Start, file.utf8CodeUnitCount, function.utf8Start, function.utf8CodeUnitCount, name?.utf8Start, name?.utf8CodeUnitCount ?? 0, colour)
        if callstack > 0 {
            self.ctx = ___tracy_emit_zone_begin_alloc_callstack(loc, callstack, active ? 1 : 0)
        } else {
            self.ctx = ___tracy_emit_zone_begin_alloc(loc, active ? 1 : 0)
        }
    }

    @inlinable
    @inline(__always)
    public func name(_ name: String) {
        ___tracy_emit_zone_name(self.ctx, name, name.count)
    }

    @inlinable
    @inline(__always)
    public func text(_ msg: String) {
        ___tracy_emit_zone_text(self.ctx, msg, msg.count)
    }

    @inlinable
    @inline(__always)
    public func value(_ val: Int) {
        ___tracy_emit_zone_value(self.ctx, UInt64(val))
    }

    @inlinable
    @inline(__always)
    public func end() {
        ___tracy_emit_zone_end(self.ctx)
    }
}

