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

// swift-tracy demo
//
// Demonstrates all instrumentation primitives provided by the Tracy library
// and exercises the malloc interposition layer so you can verify memory
// tracking works on your platform.
//
// ─── How to run ───────────────────────────────────────────────────────────────
//
//   SWIFT_TRACY_ENABLE=true swift run swift-tracy-demo
//
// ─── How to connect the Tracy GUI ─────────────────────────────────────────────
//
//   1. Open the Tracy profiler GUI (tracy-profiler).
//   2. Click "Connect" — it will wait for a client.
//   3. Start the demo (or start the GUI after the demo is already running;
//      Tracy buffers data and will send it when the GUI connects).
//
// ─── What to look for ─────────────────────────────────────────────────────────
//
//   Timeline  — Nested zones labelled "simulationStep", "renderFrame", and
//               "memoryWorkload" appear each iteration, colour-coded by type.
//
//   Frame graph — The top of the timeline shows a ~60 fps frame graph driven
//               by the Frame() mark at the top of each loop iteration.
//               Two discontinuous frame sets appear as separate rows:
//               "physics" fires every frame and spans two child zones
//               (integrateForces + resolveCollisions); "ai" fires every
//               8 frames (spanning buildSpatialIndex + evaluateBehaviors),
//               so its row shows visible gaps — the intended use case for
//               discontinuous frames.
//
//   Messages  — Open the Messages panel (top menu bar). You will see per-frame
//               log entries, some in colour, correlating with zones on the
//               timeline.
//
//   Memory    — Open the Memory panel. Each iteration grows a Swift Array
//               inside a class object without reserving capacity, so Swift
//               repeatedly doubles its internal buffer (free old + alloc new).
//               You should see a rising staircase of buffer sizes, then a
//               single free when ARC releases the object at the end of the
//               call. This validates end-to-end Swift ↔ Tracy integration.
//
// ─── Building without Tracy ───────────────────────────────────────────────────
//
//   swift run swift-tracy-demo   (no env var)
//
//   The binary still runs; all Tracy calls compile to no-ops so you can use
//   this to verify the zero-overhead disabled path.

import Foundation
import Tracy

// Populate the "Trace Info" panel in the GUI with metadata about this run.
appInfo("swift-tracy demo — \(ProcessInfo.processInfo.operatingSystemVersionString)")

print("""
swift-tracy demo
────────────────
Build & run:  SWIFT_TRACY_ENABLE=true swift run swift-tracy-demo
Then open the Tracy GUI and click "Connect".

Panels to watch:
  Timeline    — nested zones per frame
  Frame graph — ~60 fps driven by Frame() marks
  Messages    — per-frame log entries
  Memory      — malloc/realloc/free events (tests interposition)

Press Ctrl-C to stop.
""")

// ─── Main loop ────────────────────────────────────────────────────────────────
// Simulates a simple game-style loop: physics + render at ~60 fps.

var frameIndex: UInt64 = 0

while true {
    // frame() marks the boundary between continuous frames and drives the
    // frame graph at the top of the Tracy timeline.
    frame()

    frameIndex &+= 1

    // A coloured message at the start of each frame appears in the Messages
    // panel and can be correlated with zones on the timeline.
    // Colour is 0xRRGGBB.
    message("frame \(frameIndex)", colour: 0x44aaff)

    simulationStep(frame: frameIndex)
    renderFrame(frame: frameIndex)
    memoryWorkload()

    // ~60 fps
    Thread.sleep(forTimeInterval: 1.0 / 60.0)
}

// ─── Simulation ───────────────────────────────────────────────────────────────

func simulationStep(frame: UInt64) {
    // #Zone captures the source location at compile time (zero runtime overhead
    // for the location data). The name: parameter overrides the default function
    // name shown in the Tracy GUI.
    let z = #Zone(colour: 0x44ff88) // custom colour
    defer { z.end() }

    // Work before the physics bracket — visible in the timeline as part of
    // simulationStep but outside the "physics" discontinuous frame row.
    processInput()

    // "physics" spans two child zones each frame — the discontinuous frame row
    // in the Tracy GUI shows a dense bar grouping both steps together.
    frameStart("physics")
    integrateForces(frame: frame)
    resolveCollisions()
    frameEnd("physics")

    // Post-physics work, also outside the bracket, so zooming in on the
    // timeline clearly shows the frame mark as a sub-span of this zone.
    syncEntities()

    // "ai" runs every 8 frames, so its row has visible gaps that make the
    // discontinuous frame feature easy to spot in the timeline.
    if frame % 8 == 0 {
        frameStart("ai")
        buildSpatialIndex()
        evaluateBehaviors()
        frameEnd("ai")
    }

    // z.text() attaches arbitrary runtime data to the zone — visible when
    // you click the zone bar in the Tracy timeline.
    z.text("frame=\(frame)")
}

func integrateForces(frame: UInt64) {
    let z = #Zone(colour: 0x22cc66)
    defer { z.end() }

    // Simulate work proportional to frame number so the zone duration varies
    // visibly in the timeline.
    var sum: Double = 0
    let iterations = 1000 + Int(frame % 500)
    for i in 0 ..< iterations {
        sum += sin(Double(i) * 0.001)
    }

    // z.value() attaches a numeric value to the zone — shown in the tooltip
    // and plottable as a graph in the Statistics panel.
    z.value(iterations)

    _ = sum // prevent optimisation
}

func resolveCollisions() {
    let z = #Zone(colour: 0x11aa55)
    defer { z.end() }

    var sum: Double = 0
    for i in 0 ..< 300 {
        sum += cos(Double(i) * 0.007)
    }
    _ = sum
}

func processInput() {
    let z = #Zone(colour: 0x44aaff)
    defer { z.end() }

    var sum: Double = 0
    for i in 0 ..< 200 {
        sum += sin(Double(i) * 0.003)
    }
    _ = sum
}

func syncEntities() {
    let z = #Zone(colour: 0x2288cc)
    defer { z.end() }

    var sum: Double = 0
    for i in 0 ..< 250 {
        sum += cos(Double(i) * 0.005)
    }
    _ = sum
}

func buildSpatialIndex() {
    let z = #Zone(colour: 0x8844ff)
    defer { z.end() }

    var sum: Double = 0
    for i in 0 ..< 500 {
        sum += sqrt(Double(i + 1))
    }
    _ = sum
}

func evaluateBehaviors() {
    let z = #Zone(colour: 0xaa66ff)
    defer { z.end() }

    var sum: Double = 0
    for i in 0 ..< 400 {
        sum += log(Double(i + 1))
    }
    _ = sum
}

// ─── Rendering ────────────────────────────────────────────────────────────────

func renderFrame(frame: UInt64) {
    let z = #Zone(name: "mainRenderLoop", colour: 0xff8822) // custom name and colour
    defer { z.end() }

    drawScene(frame: frame)
}

func drawScene(frame: UInt64) {
    let z = #Zone(colour: 0xffaa44)
    defer { z.end() }

    // Demonstrate a message without colour — appears in the Messages panel
    // as a plain white entry.
    if frame % 60 == 0 {
        message("completed 60 frames")
    }

    // Simulate per-object draw calls as child zones.
    for i in 0 ..< 5 {
        drawObject(index: i)
    }
}

func drawObject(index: Int) {
    // Zone initialiser alternative to the macro — same semantics, slightly
    // higher runtime overhead (uses _alloc variants which copy source location
    // data per call rather than reusing a static).
    let z = #Zone
    defer { z.end() }

    var sum: Double = 0
    for j in 0 ..< 200 {
        sum += cos(Double(j + index) * 0.01)
    }

    _ = sum
}

// ─── Memory ───────────────────────────────────────────────────────────────────
// Demonstrates Swift-native memory tracking via the interposition layer.
//
// Wrapping the array in a class makes the ARC lifetime explicit: one heap
// allocation for the object itself, followed by a series of buffer reallocations
// as Swift doubles the array's internal storage on each overflow, then a final
// free of both the buffer and the object when the last strong reference drops.

private final class GrowingBuffer {
    var elements: [UInt64] = []
}

func memoryWorkload() {
    let z = #Zone
    defer { z.end() }

    // Append without reserving capacity so Swift must grow the backing buffer
    // repeatedly (exponential doubling). In the Tracy memory panel this looks
    // like a staircase: free(old) + alloc(2× larger) on each overflow.
    let buf = GrowingBuffer()
    for i in 0 ..< 4096 {
        buf.elements.append(UInt64(i))
    }
    // ARC releases `buf` here, freeing the array buffer then the class object.
}
