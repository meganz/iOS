import MEGAPreference

enum VideoPlayerPreferenceKeyEntity: PreferenceKeyProtocol {
    case playbackResumePositions

    var rawValue: String {
        switch self {
        case .playbackResumePositions: "playbackResumePositions"
        }
    }
}
