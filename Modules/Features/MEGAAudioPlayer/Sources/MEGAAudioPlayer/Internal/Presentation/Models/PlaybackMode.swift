import Foundation

/// Music vs Podcast mode in the audio player. 
enum PlaybackMode: Hashable {
    case music
    case podcast

    var toggled: PlaybackMode {
        switch self {
        case .music: .podcast
        case .podcast: .music
        }
    }
}
