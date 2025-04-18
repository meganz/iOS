public struct RequestEntity: Sendable, Equatable {
    public let nodeHandle: HandleEntity
    public let type: RequestTypeEntity
    public let progress: Double
    public let flag: Bool
    public let accountRequest: AccountRequestEntity?
    
    public init(
        nodeHandle: HandleEntity = .invalid,
        type: RequestTypeEntity,
        progress: Double = 0,
        flag: Bool = false,
        accountRequest: AccountRequestEntity? = nil
    ) {
        self.type = type
        self.progress = progress
        self.flag = flag
        self.nodeHandle = nodeHandle
        self.accountRequest = accountRequest
    }
}
