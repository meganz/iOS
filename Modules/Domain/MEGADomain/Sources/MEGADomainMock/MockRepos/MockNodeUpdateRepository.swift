import MEGADomain

public final class MockNodeUpdateRepository: NodeUpdateRepositoryProtocol {
    public static var newRepo: MockNodeUpdateRepository { MockNodeUpdateRepository() }
    
    public var shouldProcessOnNodesUpdateCalled = false
    private let shouldProcessOnNodesUpdate: Bool
    
    public init(shouldProcessOnNodesUpdate: Bool = true) {
        self.shouldProcessOnNodesUpdate = shouldProcessOnNodesUpdate
    }
    
    public func shouldProcessOnNodesUpdate(parentNode: NodeEntity, childNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        shouldProcessOnNodesUpdateCalled = true
        return shouldProcessOnNodesUpdate
    }
}
