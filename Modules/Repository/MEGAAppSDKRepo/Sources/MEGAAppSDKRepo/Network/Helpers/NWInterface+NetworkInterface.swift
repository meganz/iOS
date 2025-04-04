import Network

extension NWInterface: NetworkInterface {
    public var interfaceType: NetworkInterfaceType {
        type.toNetworkInterfaceType()
    }
}
