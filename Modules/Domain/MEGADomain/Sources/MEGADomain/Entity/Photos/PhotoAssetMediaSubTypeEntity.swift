public struct PhotoAssetMediaSubtypeEntity: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    // MARK: - Photo Subtypes
    public static let photoPanorama       = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 0)
    public static let photoHDR            = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 1)
    public static let photoScreenshot     = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 2)
    public static let photoLive           = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 3)
    public static let photoDepthEffect    = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 4)
    public static let spatialMedia        = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 10)

    // MARK: - Video Subtypes
    public static let videoStreamed       = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 16)
    public static let videoHighFrameRate  = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 17)
    public static let videoTimelapse      = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 18)
    public static let videoScreenRecording = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 19)
    public static let videoCinematic      = PhotoAssetMediaSubtypeEntity(rawValue: 1 << 21)
}
