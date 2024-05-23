
import TracyC

// Fast navigation in large data sets and correlating zones with what is
// happening in the application may be difficult. To ease these issues, you can
// issue a message (e.g. typical debug output) to the trace log.

@inlinable
@inline(__always)
public func message(_ text: StaticString, callstack: Int32 = 0)
{
    ___tracy_emit_messageL(text.utf8Start, callstack)
}

@inlinable
@inline(__always)
public func message(_ text: StaticString, colour: UInt32, callstack: Int32 = 0)
{
    ___tracy_emit_messageLC(text.utf8Start, colour, callstack)
}


// XXX: Prefer the StaticString variants above as these will not need to copy
// the string data.

@inlinable
@inline(__always)
public func message(_ text: String, callstack: Int32 = 0)
{
    ___tracy_emit_message(text, text.count, callstack)
}

@inlinable
@inline(__always)
public func message(_ text: String, colour: UInt32, callstack: Int32 = 0)
{
    ___tracy_emit_messageC(text, text.count, colour, callstack)
}

// Add additional information about the profiled application to the trace
// description (e.g. source repository version, application environment, etc.)
@inlinable
@inline(__always)
public func appInfo(_ info: String)
{
    ___tracy_emit_message_appinfo(info, info.count)
}

