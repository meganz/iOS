public enum VideoPlayerOption: String, CaseIterable, Identifiable, Sendable {
    case vlc = "VLCKit"
    case avPlayer = "AVPlayer"

    public var id: String { rawValue }
}
