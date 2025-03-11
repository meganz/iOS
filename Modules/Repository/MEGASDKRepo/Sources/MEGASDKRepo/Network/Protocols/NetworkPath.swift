import Network

/// Represents the current status of a network path.
public enum NetworkPathStatus: Sendable {
    case satisfied
    case unsatisfied
    case requiresConnection
}

/// A protocol that abstracts the properties and methods of `NWPath`.
public protocol NetworkPath: Sendable {
    
    /// The current status of the network path.
    var networkStatus: NetworkPathStatus { get }

    /// The list of available network interfaces. E.g.: wifi, cellular, wiredEthernet, etc.
    var availableNetworkInterfaces: [any NetworkInterface] { get }

    /// Checks whether the network path uses the specified interface type.
    /// - Parameter type: The type of the network interface.
    /// - Returns: `true` if the network path uses the specified interface type, otherwise `false`.
    func usesNetworkInterfaceType(_ type: NetworkInterfaceType) -> Bool
}
