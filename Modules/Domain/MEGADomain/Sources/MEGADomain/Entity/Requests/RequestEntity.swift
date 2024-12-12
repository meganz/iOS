public struct RequestEntity: Sendable, Equatable {
    public let type: RequestTypeEntity
    public let progress: Double
    
    public init(type: RequestTypeEntity, progress: Double = 0) {
        self.type = type
        self.progress = progress
    }
}
