import MEGADomain

public struct NavigateToContentActionEntity {
    public let type: ContextAction.Category
    public let node: NodeEntity
    public let error: String?
    
    public init(
        type: ContextAction.Category,
        node: NodeEntity,
        error: String?
    ) {
        self.type = type
        self.node = node
        self.error = error
    }
}
