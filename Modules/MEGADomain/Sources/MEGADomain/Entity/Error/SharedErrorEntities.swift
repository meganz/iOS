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
