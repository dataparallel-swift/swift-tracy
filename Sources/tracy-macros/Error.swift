
enum TracyMacroError : CustomStringConvertible, Error {
    case missingArgument(String)
    case invalidArgument(String)
    case invalidLocation

    var description: String {
        switch self {
            case .missingArgument(let name): return "Missing required argument: \(name)"
            case .invalidArgument(let name): return "Invalid argument: \(name)"
            case .invalidLocation: return "Could not determine source location"
        }
    }
}

