
import SwiftSyntax
import SwiftSyntaxMacros

public struct ZoneScoped : CodeItemMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax]
    {
        let loc  = context.makeUniqueName("loc")
        let ctx  = context.makeUniqueName("ctx")

        let function : ExprSyntax = "UnsafeRawPointer(StaticString(stringLiteral: #function).utf8Start).assumingMemoryBound(to: CChar.self)"
        let file : ExprSyntax = "UnsafeRawPointer(StaticString(stringLiteral: #file).utf8Start).assumingMemoryBound(to: CChar.self)"
        var name : ExprSyntax = "nil"
        var colour : ExprSyntax = "0"
        var callstack : ExprSyntax? = nil

        for arg in node.arguments {
            if let label = arg.label?.text {
                switch label {
                    case "name":
                        name = "UnsafeRawPointer(StaticString(stringLiteral: \(arg.expression)).utf8Start).assumingMemoryBound(to: CChar.self)"

                    case "colour":
                        colour = arg.expression

                    case "callstack":
                        callstack = arg.expression

                    default:
                        throw TracyMacroError.invalidArgument("\(label)")
                }
            }
        }

        return
            [ "var \(loc) = ___tracy_source_location_data(name: \(name), function: \(function), file: \(file), line: #line, color: \(colour))"
            , callstack != nil
            ? "let \(ctx) = ___tracy_emit_zone_begin_callstack(&\(loc), \(callstack!), 1)"
            : "let \(ctx) = ___tracy_emit_zone_begin(&\(loc), 1)"
            , "defer { ___tracy_emit_zone_end(\(ctx)) }"
            ]
    }
}

#if false
public struct ZoneBegin : DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [ExprSyntax]
    {
        let loc  = context.makeUniqueName("loc")
        let ctx  = context.makeUniqueName("ctx")

        let function : ExprSyntax = "UnsafeRawPointer(StaticString(stringLiteral: #function).utf8Start).assumingMemoryBound(to: CChar.self)"
        let file : ExprSyntax = "UnsafeRawPointer(StaticString(stringLiteral: #file).utf8Start).assumingMemoryBound(to: CChar.self)"
        var name : ExprSyntax = "nil"
        var colour : ExprSyntax = "0"
        var callstack : ExprSyntax? = nil

        for arg in node.arguments {
            if let label = arg.label?.text {
                switch label {
                    case "name":
                        name = "UnsafeRawPointer(StaticString(stringLiteral: \(arg.expression)).utf8Start).assumingMemoryBound(to: CChar.self)"

                    case "colour":
                        colour = arg.expression

                    case "callstack":
                        callstack = arg.expression

                    default:
                        throw TracyMacroError.invalidArgument("\(label)")
                }
            }
        }

        return
            [ "var \(loc) = ___tracy_source_location_data(name: \(name), function: \(function), file: \(file), line: #line, color: \(colour))"
            , callstack != nil
            ? "let \(ctx) = ___tracy_emit_zone_begin_callstack(&\(loc), \(callstack!), 1)"
            : "let \(ctx) = ___tracy_emit_zone_begin(&\(loc), 1)"
            , "return \(ctx)"
            ]

        // return "{ \(body) }()"
    }
}

public struct ZoneEnd : ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax
    {
        guard let ctx = node.arguments.first?.expression
        else {
            throw TracyMacroError.missingArgument("context")
        }

        return "___tracy_emit_zone_end(\(ctx))"
    }
}
#endif

