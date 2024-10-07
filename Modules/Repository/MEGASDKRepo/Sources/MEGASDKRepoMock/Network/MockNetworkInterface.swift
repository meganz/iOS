import MEGASDKRepo
import Network

final public class MockNetworkInterface: NetworkInterface, @unchecked Sendable {
    private let mockType: NetworkInterfaceType

    public var interfaceType: NetworkInterfaceType {
        mockType
    }
    
    public init(type: NetworkInterfaceType) {
        self.mockType = type
    }
}
