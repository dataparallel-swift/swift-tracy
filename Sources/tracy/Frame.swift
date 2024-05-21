
@_exported import TracyC

// This macro can be (optionally) used to slice the execution record of the
// program into "frames", i.e the repeated work unit of the program such as
// rendering a frame, a simulation loop. This macro is used to mark the
// transition point between continuous frames.
//
// Optionally, the 'name:' parameter can be provided, which will create a new
// set of frames for each unique name that is used.
//
@freestanding(expression)
public macro FrameMark(_ name: StaticString = .init()) -> () =
    #externalMacro(module: "TracyMacros", type: "FrameMark")

// This macro is used to mark the start of a _discontinuous_ frame; i.e. one
// that is executed periodically, with a pause between each invocation. It must
// be matched with a corresponding 'FrameMarkEnd'.
//
@freestanding(expression)
public macro FrameMarkStart(_ name: StaticString) -> () =
    #externalMacro(module: "TracyMacros", type: "FrameMarkStart")

// Mark the end of a discontinuous frame. It must be matched with a
// corresponding 'FrameMarkStart'.
@freestanding(expression)
public macro FrameMarkEnd(_ name: StaticString) -> () =
    #externalMacro(module: "TracyMacros", type: "FrameMarkEnd")

