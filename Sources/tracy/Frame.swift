
import TracyC

// This macro can be (optionally) used to slice the execution record of the
// program into "frames", i.e the repeated work unit of the program such as
// rendering a frame, a simulation loop. This macro is used to mark the
// transition point between continuous frames.
//
// Optionally, the 'name:' parameter can be provided, which will create a new
// set of frames for each unique name that is used.
//
// @freestanding(expression)
// public macro FrameMark(_ name: StaticString = .init()) =
//     #externalMacro(module: "TracyMacros", type: "FrameMark")

// This macro is used to mark the start of a _discontinuous_ frame; i.e. one
// that is executed periodically, with a pause between each invocation. It must
// be matched with a corresponding 'FrameMarkEnd'.
//
// @freestanding(expression)
// public macro FrameMarkStart(_ name: StaticString) =
//     #externalMacro(module: "TracyMacros", type: "FrameMarkStart")

// Mark the end of a discontinuous frame. It must be matched with a
// corresponding 'FrameMarkStart'.
// @freestanding(expression)
// public macro FrameMarkEnd(_ name: StaticString) =
//     #externalMacro(module: "TracyMacros", type: "FrameMarkEnd")


// Frames can be used to (optionally) slice the execution record into repeated
// units of work; e.g. the rendering of a frame, a simulation loop, etc. This
// marks the transition point between frames.
//
public struct Frame {
    @inlinable
    @inline(__always)
    @discardableResult
    public init() {
        ___tracy_emit_frame_mark(nil)
    }

    @inlinable
    @inline(__always)
    @discardableResult
    public init(_ name: StaticString) {
        ___tracy_emit_frame_mark(name.utf8Start)
    }
}

