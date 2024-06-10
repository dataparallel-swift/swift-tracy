
import SwiftSyntax
import SwiftSyntaxMacros


public struct Zone : ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax
    {
        let loc  = context.makeUniqueName("loc")
        let ctx  = context.makeUniqueName("ctx")

        // fallback to #function, although this will just produce garbage
        let function = context.lexicalContext.first?.functionName(in: context) ?? "#function"
        var name : ExprSyntax = "nil"
        var colour : ExprSyntax = "0"
        var callstack : ExprSyntax? = nil
        var active : ExprSyntax = "true"

        for arg in node.arguments {
            if let label = arg.label?.text {
                switch label {
                    case "name":
                        name = "StaticString(stringLiteral: \(arg.expression)).utf8Start"

                    case "colour":
                        colour = arg.expression

                    case "callstack":
                        callstack = arg.expression

                    case "active":
                        active = arg.expression

                    default:
                        throw TracyMacroError.invalidArgument("\(label)")
                }
            }
        }

        /* Swift does not have local static variables, which are required by
         * Tracy (otherwise you must use the _alloc functions have higher
         * overhead since they need to copy a lot of data around). We can work
         * around this by defining a local struct type with a static variable
         * inside:
         *
         * > func foo() {
         * >     struct A { static var bar = ... }
         * >     ...
         * > }
         *
         * One drawback of this trick is that we can no longer use the usual
         * #function macro, since this will return the struct name ('A' in this
         * case) not the name of the parent function ('foo') which is what we
         * are actually interested in.
         *
         * Note that we need to be _very_ careful how this struct is
         * initialised. Because Swift will not automatically cast pointer types
         * between char* and uint8_t* for _struct_ initialisers (like it will
         * for function calls) we need to wrangle the types ourselves. If we
         * follow the usual options like 'withCString' or even
         * UnsafeRawPointer(...).assumingMemoryBound(to:), we'll end up with a
         * @swift_once() initialisation function in the generated code, which we
         * don't want.
         *
         * In the end it was necessary to change the type of the source location
         * struct in the C header to have a type that aligns with what Swift
         * wants. Note that this relies on a further oddity of how Swift/C++
         * interop works, in that the header file that the Swift interop layer
         * gets its types and definitions from does _not_ have to be the same as
         * what the C++ compiler uses.
         */
        if let depth = callstack {
            return """
            {
                struct \(loc) {
                    @exclusivity(unchecked)
                    static var data = ___tracy_source_location_data(
                        name: \(name),
                        function: StaticString(stringLiteral: \(literal: function)).utf8Start,
                        file: StaticString(stringLiteral: #file).utf8Start,
                        line: #line,
                        color: \(colour))
                    }
                let \(ctx) = ___tracy_emit_zone_begin_callstack(&\(loc).data, \(depth), \(active) ? 1 : 0)
                return Tracy.Zone.init(with: \(ctx))
            }()
            """
        }
        else {
            return """
            {
                struct \(loc) {
                    @exclusivity(unchecked)
                    static var data = ___tracy_source_location_data(
                        name: \(name),
                        function: StaticString(stringLiteral: \(literal: function)).utf8Start,
                        file: StaticString(stringLiteral: #file).utf8Start,
                        line: #line,
                        color: \(colour))
                    }
                let \(ctx) = ___tracy_emit_zone_begin(&\(loc).data, \(active) ? 1 : 0)
                return Tracy.Zone.init(with: \(ctx))
            }()
            """
        }
    }
}

public struct ZoneDisabled : ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax
    {
        "return Tracy.Zone.init(with: 0)"
    }
}

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

    return "\(baseName)(\(argumentNames.joined(separator: "")))"
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

