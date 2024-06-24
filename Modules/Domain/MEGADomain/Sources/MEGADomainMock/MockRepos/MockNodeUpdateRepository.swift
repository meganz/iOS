import MEGADomain

public final class MockNodeUpdateRepository: NodeUpdateRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockNodeUpdateRepository { MockNodeUpdateRepository() }
    
    public var shouldProcessOnNodesUpdateCalled = false
    public var shouldProcessOnNodesUpdateValue: Bool
    
    public init(shouldProcessOnNodesUpdate: Bool = true) {
        self.shouldProcessOnNodesUpdateValue = shouldProcessOnNodesUpdate
    }
    
    public func shouldProcessOnNodesUpdate(parentNode: NodeEntity, childNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        shouldProcessOnNodesUpdateCalled = true
        return shouldProcessOnNodesUpdateValue
    }
}
