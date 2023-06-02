import Foundation

public struct GenericErrorEntity: Error {
    public init() { }
}

public enum NetworkErrorEntity: Error {
    case noConnection
}

public enum DeviceEnvironmentErrorEntity: Error {
    case diskFull
}

public enum NodeErrorEntity: Error {
    case nodeNotFound
}

public enum JSONCodingErrorEntity: Error, LocalizedError {
    case encoding
    case decoding
    
    public var errorDescription: String? {
        switch self {
        case .encoding: return "JSON encoding error occurred. Check if data is corrupted or not."
        case .decoding: return "JSON decoding error occurred. Check if data is corrupted or not."
        }
    }
}
