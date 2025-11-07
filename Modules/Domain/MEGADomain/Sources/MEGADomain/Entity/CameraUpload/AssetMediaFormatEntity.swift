public enum AssetMediaFormatEntity: Sendable, Equatable {
    case jpeg
    case heic
    case heif
    case png
    case dng
    case gif
    case webp
    case mov
    case mp4
    case unknown(identifier: String)
}
