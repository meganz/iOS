import Network

/// A protocol that abstracts the properties of `NWInterface`.
public protocol NetworkInterface: Sendable {
    /// The type of the network interface. E.g.:  wifi, cellular, wiredEthernet, loopback, other
    var interfaceType: NetworkInterfaceType { get }
}
