public struct VideoPlaylistElementsResultEntity: Equatable {
    let success: UInt
    let failure: UInt
    
    public init(success: UInt, failure: UInt) {
        self.success = success
        self.failure = failure
    }
}
