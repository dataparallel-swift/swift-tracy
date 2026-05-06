// Copyright (c) 2026 The swift-tracy authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import TracyC

/// Mark the transition point between continuous "frames", i.e. the repeated unit
/// of work of the program such as rendering a frame or a step in the simulation
/// loop. Optionally takes a name to track independent frame sets (e.g.
/// "physics", "render") separately.
@inlinable
@inline(__always)
public func frame(_ name: StaticString? = nil) {
    #if SWIFT_TRACY_ENABLE
    ___tracy_emit_frame_mark(name?.utf8Start)
    #endif
}

/// Mark the start of a discontinuous frame. Must be paired with FrameEnd
/// using the same name.
@inlinable
@inline(__always)
public func frameStart(_ name: StaticString) {
    #if SWIFT_TRACY_ENABLE
    ___tracy_emit_frame_mark_start(name.utf8Start)
    #endif
}

/// Mark the end of a discontinuous frame. Must be paired with FrameStart
/// using the same name.
@inlinable
@inline(__always)
public func frameEnd(_ name: StaticString) {
    #if SWIFT_TRACY_ENABLE
    ___tracy_emit_frame_mark_end(name.utf8Start)
    #endif
}
