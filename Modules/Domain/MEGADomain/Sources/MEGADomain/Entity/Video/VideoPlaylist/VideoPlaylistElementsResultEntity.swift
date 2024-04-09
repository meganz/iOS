public struct VideoPlaylistElementsResultEntity: Equatable {
    public let success: UInt
    public let failure: UInt
    
    public init(success: UInt, failure: UInt) {
        self.success = success
        self.failure = failure
    }
}
