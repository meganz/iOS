import MEGAAppSDKRepo
import Network

final public class MockNetworkPath: NetworkPath, Equatable {
    public static func == (lhs: MockNetworkPath, rhs: MockNetworkPath) -> Bool {
        lhs.networkStatus == rhs.networkStatus
        && lhs.availableNetworkInterfaces.map(\.interfaceType) == rhs.availableNetworkInterfaces.map(\.interfaceType)
    }
    
    public let mockStatus: NetworkPathStatus
    public let mockAvailableInterfaces: [any NetworkInterface]

    public init(status: NetworkPathStatus, availableInterfaces: [any NetworkInterface]) {
        self.mockStatus = status
        self.mockAvailableInterfaces = availableInterfaces
    }

    public var networkStatus: NetworkPathStatus {
        mockStatus
    }

    public var availableNetworkInterfaces: [any NetworkInterface] {
        mockAvailableInterfaces
    }

    public func usesNetworkInterfaceType(_ type: NetworkInterfaceType) -> Bool {
        mockAvailableInterfaces.contains { $0.interfaceType == type }
    }
}
