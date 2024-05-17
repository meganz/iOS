import MEGADomain
import MEGASwift

final public class MockSDKNodesUpdateListenerRepository: NodesUpdateListenerProtocol {
    public static let newRepo = MockSDKNodesUpdateListenerRepository()
    
    public var onNodesUpdateHandler: (([NodeEntity]) -> Void)?
}
