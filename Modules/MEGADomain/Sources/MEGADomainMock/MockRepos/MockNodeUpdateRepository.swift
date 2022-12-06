import MEGADomain


public struct MockNodeUpdateRepository: NodeUpdateRepositoryProtocol {
    public static let newRepo = MockNodeUpdateRepository()
    
    private let shouldProcessOnNodesUpdate: Bool
    
    public init(shouldProcessOnNodesUpdate: Bool = true) {
        self.shouldProcessOnNodesUpdate = shouldProcessOnNodesUpdate
    }
    
    public func shouldProcessOnNodesUpdate(parentNode: NodeEntity, childNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        shouldProcessOnNodesUpdate
    }
}
