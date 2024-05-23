
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
public struct Zone : ~Copyable {
    // This is fucked. Because (a) swift does not follow lexical lifetime for
    // the struct as a whole; and (b) it insists on copying data around
    // needlessly, we need to use the _alloc versions of functions which adds
    // unnecessary time and memory overhead to every call. One potential upside
    // of this is that we could also relax the call to be any String type rather
    // than restricting it to StaticString, but maybe one day we can unfuck this
    // thing so we'll keep the more restrictive API for now.
    @usableFromInline
    let loc : UInt64
    @usableFromInline
    let ctx : TracyCZoneCtx

    @inlinable
    @inline(__always)
    public init(function: StaticString = #function, file: StaticString = #file, line: UInt32 = #line, colour: UInt32 = 0, callstack: Int32 = 0) {
        // We don't care about the number of UTF-8 code points, we care about
        // the number of bytes to be copied, so just assert that it is ASCII.
        assert(function.isASCII)
        assert(file.isASCII)

        self.loc = ___tracy_alloc_srcloc(line, file.utf8Start, file.utf8CodeUnitCount, function.utf8Start, function.utf8CodeUnitCount, colour)
        if callstack > 0 {
            self.ctx = ___tracy_emit_zone_begin_alloc_callstack(self.loc, callstack, 1)
        } else {
            self.ctx = ___tracy_emit_zone_begin_alloc(self.loc, 1)
        }
    }

    @inlinable
    @inline(__always)
    public init(name: StaticString, function: StaticString = #function, file: StaticString = #file, line: UInt32 = #line, colour: UInt32 = 0, callstack: Int32 = 0) {
        // We don't care about the number of UTF-8 code points, we care about
        // the number of bytes to be copied, so just assert that it is ASCII.
        assert(function.isASCII)
        assert(file.isASCII)
        assert(name.isASCII)

        self.loc = ___tracy_alloc_srcloc_name(line, file.utf8Start, file.utf8CodeUnitCount, function.utf8Start, function.utf8CodeUnitCount, name.utf8Start, name.utf8CodeUnitCount, colour)
        if callstack > 0 {
            self.ctx = ___tracy_emit_zone_begin_alloc_callstack(self.loc, callstack, 1)
        } else {
            self.ctx = ___tracy_emit_zone_begin_alloc(self.loc, 1)
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
    public consuming func end() {
        ___tracy_emit_zone_end(self.ctx)
        discard self
    }

    @inlinable
    @inline(__always)
    deinit {
        ___tracy_emit_zone_end(self.ctx)
    }
}

