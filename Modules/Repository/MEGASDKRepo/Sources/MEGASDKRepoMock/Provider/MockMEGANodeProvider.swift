import MEGADomain
import MEGASdk
import MEGASDKRepo

public struct MockMEGANodeProvider: MEGANodeProviderProtocol {
    private let node: MEGANode?
    
    public init(node: MEGANode? = nil) {
        self.node = node
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        node
    }
}
