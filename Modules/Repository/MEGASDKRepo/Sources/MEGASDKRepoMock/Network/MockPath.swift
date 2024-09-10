import MEGASDKRepo
import Network

final public class MockPath: NetworkPath {
    public let mockStatus: NetworkPathStatus
    public let mockAvailableInterfaces: [NetworkInterface]

    public init(status: NetworkPathStatus, availableInterfaces: [NetworkInterface]) {
        self.mockStatus = status
        self.mockAvailableInterfaces = availableInterfaces
    }

    public var networkStatus: NetworkPathStatus {
        mockStatus
    }

    public var availableNetworkInterfaces: [NetworkInterface] {
        mockAvailableInterfaces
    }

    public func usesNetworkInterfaceType(_ type: NetworkInterfaceType) -> Bool {
        mockAvailableInterfaces.contains { $0.interfaceType == type }
    }
}
