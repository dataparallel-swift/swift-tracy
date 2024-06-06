
@_exported import TracyC

// A zone represents some period you want to record in the profiler. Typically
// this is used to measure the duration of a whole scope of a profiled function,
// but can also be used to measure time spent in the scopes of a for-loop or
// if-branch.
//
// Place this macro at the beginning of the scope/region/etc. that you want to
// measure. The macro can optionally take 'name:' and 'colour:' parameters, to set a
// custom colour and name for the zone. The call stack can also be collected
// with the zone by specifying the 'callstack:' parameter, which specifies the
// depth of the callstack to capture. See the Tracy manual for further
// information regarding callstack collection.zone
//
// As there is no automatic destruction mechanism, you must manually mark where
// the zone ends.
//
// NOTE: This seems to require Swift 6 (-dev) in order to extract the function name
//
@freestanding(expression)
public macro Zone(name: StaticString = .init(), colour: UInt32 = 0, callstack: Int32 = 0, active: Bool = true) -> Zone =
    #externalMacro(module: "TracyMacros", type: "Zone")

public struct Zone {
    @usableFromInline
    let ctx : TracyCZoneCtx

    @inlinable
    @inline(__always)
    public init(with context: TracyCZoneCtx) {
        self.ctx = context
    }

    // Prefer to use the #Zone macro whenever possible
    @inlinable
    @inline(__always)
    public init(name: StaticString? = nil, colour: UInt32 = 0, callstack: Int32 = 0, active: Bool = true,
        /* don't specify */ function: StaticString = #function,
        /* don't specify */ file: StaticString = #file,
        /* don't specify */ line: UInt32 = #line)
    {
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
    public func colour(_ colour: UInt32) {
        ___tracy_emit_zone_color(self.ctx, colour)
    }

    @inlinable
    @inline(__always)
    public func end() {
        ___tracy_emit_zone_end(self.ctx)
    }
}

