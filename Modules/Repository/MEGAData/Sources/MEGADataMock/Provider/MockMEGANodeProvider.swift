import MEGAData
import MEGADomain
import MEGASdk

public struct MockMEGANodeProvider: MEGANodeProviderProtocol {
    private let node: MEGANode?
    
    public init(node: MEGANode? = nil) {
        self.node = node
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        node
    }
}
