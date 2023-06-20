import Foundation

public enum PlaybackContinuationStatusEntity: Equatable {
    case startFromBeginning
    case displayDialog(playbackTime: TimeInterval)
    case resumeSession(playbackTime: TimeInterval)
}
