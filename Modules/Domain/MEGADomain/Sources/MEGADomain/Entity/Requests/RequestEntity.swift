public struct RequestEntity: Sendable, Equatable {
    public let nodeHandle: HandleEntity
    public let type: RequestTypeEntity
    public let progress: Double
    public let flag: Bool
    
    public init(nodeHandle: HandleEntity = .invalid, type: RequestTypeEntity, progress: Double = 0, flag: Bool = false) {
        self.type = type
        self.progress = progress
        self.flag = flag
        self.nodeHandle = nodeHandle
    }
}
