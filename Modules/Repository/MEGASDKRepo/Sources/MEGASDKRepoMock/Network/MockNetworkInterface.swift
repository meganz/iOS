import MEGASDKRepo
import Network

final public class MockNetworkInterface: NetworkInterface, @unchecked Sendable {
    public static func == (lhs: MockNetworkInterface, rhs: MockNetworkInterface) -> Bool {
        lhs.interfaceType == rhs.interfaceType
    }
    
    private let mockType: NetworkInterfaceType

    public var interfaceType: NetworkInterfaceType {
        mockType
    }
    
    public init(type: NetworkInterfaceType) {
        self.mockType = type
    }
}
