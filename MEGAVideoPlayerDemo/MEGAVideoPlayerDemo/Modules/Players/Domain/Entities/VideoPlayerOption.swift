enum VideoPlayerOption: String, CaseIterable, Identifiable {
    case vlc = "VLCKit"
    case avPlayer = "AVPlayer"

    var id: String { rawValue }
}
