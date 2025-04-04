import Network

extension NWPath: NetworkPath {
    public var networkStatus: NetworkPathStatus {
        status.toNetworkPathStatus()
    }
    
    public var availableNetworkInterfaces: [any NetworkInterface] {
        availableInterfaces
    }
    
    public func usesNetworkInterfaceType(_ type: NetworkInterfaceType) -> Bool {
        usesInterfaceType(type.toNetworkInterfaceType())
    }
}
