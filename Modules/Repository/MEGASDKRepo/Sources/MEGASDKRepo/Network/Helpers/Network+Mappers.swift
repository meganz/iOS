import Network

extension NWPath.Status {
    func toNetworkPathStatus() -> NetworkPathStatus {
        switch self {
        case .satisfied: NetworkPathStatus.satisfied
        case .unsatisfied: NetworkPathStatus.unsatisfied
        case .requiresConnection: NetworkPathStatus.requiresConnection
        @unknown default: NetworkPathStatus.unsatisfied
        }
    }
}

extension NetworkInterfaceType {
    func toNetworkInterfaceType() -> NWInterface.InterfaceType  {
        switch self {
        case .other: NWInterface.InterfaceType.other
        case .wifi: NWInterface.InterfaceType.wifi
        case .cellular: NWInterface.InterfaceType.cellular
        case .wiredEthernet: NWInterface.InterfaceType.wiredEthernet
        case .loopback: NWInterface.InterfaceType.loopback
        }
    }
}

extension NWInterface.InterfaceType {
    func toNetworkInterfaceType() -> NetworkInterfaceType {
        switch self {
        case .other: NetworkInterfaceType.other
        case .wifi: NetworkInterfaceType.wifi
        case .cellular: NetworkInterfaceType.cellular
        case .wiredEthernet: NetworkInterfaceType.wiredEthernet
        case .loopback: NetworkInterfaceType.loopback
        @unknown default: NetworkInterfaceType.other
        }
    }
}

