public struct AssetMediaTypeEntity: Sendable, Equatable {
    public let mediaFormat: AssetMediaFormatEntity
    public let isBurst: Bool
    
    public init(mediaFormat: AssetMediaFormatEntity, isBurst: Bool) {
        self.mediaFormat = mediaFormat
        self.isBurst = isBurst
    }
}
