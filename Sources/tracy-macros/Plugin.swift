
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TracyMacros : CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        // marking frames
        FrameMark.self,
        FrameMarkStart.self,
        FrameMarkEnd.self,

        // marking zones
        ZoneScoped.self
    ]
}

