// Copyright (c) 2025 The swift-tracy authors. All rights reserved.
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

import SwiftSyntax
import SwiftSyntaxMacros

public struct FrameMark: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext
    ) -> ExprSyntax {
        // Note: [Handling strings in Tracy with Swift/C++ interop]
        //
        // Make sure we compile to the right IR. By default Swift will import
        // functions taking string (const char*) arguments as expecting a
        // regular Swift (heap allocated, reference counted) string, but we need
        // this data to be in the constant section so that it exists for the
        // lifetime of the program (this includes the time _after_ the main
        // function has exited).
        //
        // The swift compiler does seem to be doing string interning/pooling for
        // us (at least in release mode, which is all we care about).
        if let argument = node.arguments.first?.expression {
            if argument.as(StringLiteralExprSyntax.self) != nil {
                return "___tracy_emit_frame_mark(StaticString(\(argument)).utf8Start)"
            }
            else {
                return "___tracy_emit_frame_mark(\(argument).utf8Start)"
            }
        }
        else {
            return "___tracy_emit_frame_mark(nil)"
        }
    }
}

public struct FrameMarkStart: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            throw TracyMacroError.missingArgument("name")
        }

        if argument.as(StringLiteralExprSyntax.self) != nil {
            return "___tracy_emit_frame_mark_start(StaticString(\(argument)).utf8Start)"
        }
        else {
            return "___tracy_emit_frame_mark_start(\(argument).utf8Start)"
        }
    }
}

public struct FrameMarkEnd: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in _: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            throw TracyMacroError.missingArgument("name")
        }

        if argument.as(StringLiteralExprSyntax.self) != nil {
            return "___tracy_emit_frame_mark_end(StaticString(\(argument)).utf8Start)"
        }
        else {
            return "___tracy_emit_frame_mark_end(\(argument).utf8Start)"
        }
    }
}
