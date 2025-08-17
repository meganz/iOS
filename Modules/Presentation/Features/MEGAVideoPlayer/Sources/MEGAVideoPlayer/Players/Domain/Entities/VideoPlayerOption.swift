public enum VideoPlayerOption: String, CaseIterable, Identifiable, Sendable {
    case avPlayer = "AVPlayer"
    case placeHolder = "PlaceHolder"

    public var id: String { rawValue }
}
