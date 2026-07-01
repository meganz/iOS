import Foundation

enum PlayerLoadingState: Equatable {
    case loading
    case ready
    case playing
    case paused
}

extension PlayerLoadingState {
    init(status: PlaybackStatus, hasPlayedOnceBefore: Bool, isReady: Bool) {
        switch status {
        case .playing:
            self = .playing
        case .paused, .error:
            self = .paused
        case .loading, .buffering:
            if hasPlayedOnceBefore {
                self = .playing
            } else {
                self = isReady ? .ready : .loading
            }
        }
    }
}
