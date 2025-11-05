// Copyright (c) 2025 PassiveLogic, Inc.

enum TracyMacroError: CustomStringConvertible, Error {
    case missingArgument(String)
    case invalidArgument(String)
    case invalidLocation

    var description: String {
        switch self {
            case let .missingArgument(name): return "Missing required argument: \(name)"
            case let .invalidArgument(name): return "Invalid argument: \(name)"
            case .invalidLocation: return "Could not determine source location"
        }
    }
}
