import MEGADomain

public struct NavigateToContentActionEntity {
    public let type: DeviceCenterActionType
    public let node: NodeEntity
    public let error: String?
    
    public init(
        type: DeviceCenterActionType,
        node: NodeEntity,
        error: String?
    ) {
        self.type = type
        self.node = node
        self.error = error
    }
}
