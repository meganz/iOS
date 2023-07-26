import MEGADomain
import MEGASdk
import MEGASDKRepo

public class MockMEGANodeProvider: MEGANodeProviderProtocol {
    
    private var nodes: [MEGANode]
        
    public init(node: MEGANode? = nil) {
        self.nodes = [node].compactMap { $0 }
    }
    public init(nodes: [MEGANode]) {
        self.nodes = nodes
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        nodes.first { $0.handle == handle }
    }
}

// MARK: Testing helpers to mutate model
extension MockMEGANodeProvider {
    public func set(nodes: [MEGANode]) {
        self.nodes = nodes
    }
}
