
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

        // guard let sloc = context.location(of: node)
        // else {
        //     throw TracyMacroError.invalidLocation
        // }
        // let function : String = context.lexicalContext.first?.functionName(in: context) ?? "<unknown>"
        // let function : String = "<unknown>"

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

        return [
            """
            var \(loc) = ___tracy_source_location_data(
                              name: \(name),
                              function: UnsafeRawPointer(StaticString(stringLiteral: #function).utf8Start).assumingMemoryBound(to: CChar.self),
                              file: UnsafeRawPointer(StaticString(stringLiteral: #file).utf8Start).assumingMemoryBound(to: CChar.self),
                              line: #line,
                              color: \(colour))
            """
            , callstack != nil
            ? "var \(ctx) = ___tracy_emit_zone_begin_callstack(&\(loc), \(callstack!), 1)"
            : "let \(ctx) = ___tracy_emit_zone_begin(&\(loc), 1)"
            , "defer { ___tracy_emit_zone_end(\(ctx)) }"
            ]
    }
}

#if false
// Stolen from swift-syntax@600.0.0-prerelease-2024-05-14:Tests/SwiftSyntaxMacroExpansionTest/LexicalContextTests.swift

fileprivate extension PatternBindingSyntax {
  // When the variable is declaring a single binding, produce the name of that binding
  var singleBindingName: String? {
    if let identifierPattern = pattern.as(IdentifierPatternSyntax.self) {
      return identifierPattern.identifier.trimmedDescription
    }

    return nil
  }
}

fileprivate extension TokenSyntax {
  var asIdentifierToken: TokenSyntax? {
    switch tokenKind {
    case .identifier, .dollarIdentifier: return self.trimmed
    default: return nil
    }
  }
}

fileprivate extension FunctionParameterSyntax {
  var argumentName: TokenSyntax? {
    // If we have two names, the first one is the argument label
    if secondName != nil {
      return firstName.asIdentifierToken
    }

    // If we have only one name, it might be an argument label.
    if let superparent = parent?.parent?.parent, superparent.is(SubscriptDeclSyntax.self) {
      return nil
    }

    return firstName.asIdentifierToken
  }
}

fileprivate extension SyntaxProtocol {
  // Form a function name.
  func formFunctionName(
    _ baseName: String,
    _ parameters: FunctionParameterClauseSyntax?
  ) -> String
  {
    let argumentNames: [String] =
      parameters?.parameters.map { param in
        let argumentLabelText = param.argumentName?.text ?? "_"
        return argumentLabelText + ":"
      } ?? []

    if argumentNames.isEmpty {
        return baseName
    } else {
        return "\(baseName)(\(argumentNames.joined(separator: "")))"
    }
  }

  // Form the #function name for the given node.
  func functionName<Context: MacroExpansionContext>(
    in context: Context
  ) -> String?
  {
    // Declarations with parameters.
    // FIXME: Can we abstract over these?
    if let function = self.as(FunctionDeclSyntax.self) {
      return formFunctionName(
        function.name.trimmedDescription,
        function.signature.parameterClause
      )
    }

    if let initializer = self.as(InitializerDeclSyntax.self) {
      return formFunctionName("init", initializer.signature.parameterClause)
    }

    if let subscriptDecl = self.as(SubscriptDeclSyntax.self) {
      return formFunctionName(
        "subscript",
        subscriptDecl.parameterClause
      )
    }

    if let enumCase = self.as(EnumCaseElementSyntax.self) {
      guard let associatedValue = enumCase.parameterClause else {
        return enumCase.name.text
      }

      let argumentNames = associatedValue.parameters.map { param in
        guard let firstName = param.firstName else {
          return "_:"
        }

        return firstName.text + ":"
      }.joined()

      return "\(enumCase.name.text)(\(argumentNames))"
    }

    // Accessors use their enclosing context, i.e., a subscript or pattern binding.
    if self.is(AccessorDeclSyntax.self) {
      guard let lexicalContext = context.lexicalContext.dropFirst().first else {
        return nil
      }

      return lexicalContext.functionName(in: context)
    }

    // All declarations with identifiers.
    if let identified = self.asProtocol(NamedDeclSyntax.self) {
      return identified.name.trimmedDescription
    }

    // Extensions
    if let extensionDecl = self.as(ExtensionDeclSyntax.self) {
      // FIXME: It would be nice to be able to switch on type syntax...
      let extendedType = extensionDecl.extendedType
      if let simple = extendedType.as(IdentifierTypeSyntax.self) {
        return simple.name.trimmedDescription
      }

      if let member = extendedType.as(MemberTypeSyntax.self) {
        return member.name.trimmedDescription
      }
    }

    // Pattern bindings.
    if let patternBinding = self.as(PatternBindingSyntax.self),
      let singleVarName = patternBinding.singleBindingName
    {
      return singleVarName
    }

    return nil
  }
}
#endif

