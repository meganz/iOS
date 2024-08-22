import Foundation
import MEGASwift

public protocol PlaybackContinuationUseCaseProtocol: Sendable {
    func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity
    func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity)
    func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    )
}

public final class PlaybackContinuationUseCase<
    T: PreviousPlaybackSessionRepositoryProtocol
>: PlaybackContinuationUseCaseProtocol {
    public enum Constants {
        /// The number of seconds before a playback full duration that will determine when the playback has ended.
        /// If this threshold is reached then the session will not be resumed in the future.
        public static var completedPlaybackThreshold: TimeInterval { 2.seconds }
        
        /// The minimum playback time required to save a playback session to be resumed in the future.
        /// If playback is less than this value, then the session will not be saved and resumed in the future.
        public static var minimumContinuationPlaybackTime: TimeInterval { 15.minutes }
    }
    
    private let currentPreference: Atomic<PlaybackContinuationPreferenceStatusEntity?> = Atomic(wrappedValue: nil)
    
    private let previousSessionRepo: T
    
    public init(previousSessionRepo: T) {
        self.previousSessionRepo = previousSessionRepo
    }
    
    public func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        guard let previousTimeInterval = previousSessionRepo.timeInterval(for: fingerprint),
              previousTimeInterval >= Constants.minimumContinuationPlaybackTime else {
            return .startFromBeginning
        }
        
        guard let currentPreference = currentPreference.wrappedValue else { return .displayDialog(playbackTime: previousTimeInterval) }
        
        switch currentPreference {
        case .restartFromBeginning: return .startFromBeginning
        case .resumePreviousSession: return .resumeSession(playbackTime: previousTimeInterval)
        }
    }
    
    public func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {
        currentPreference.mutate { $0 = preferenceStatus }
    }
    
    public func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) {
        guard timeInterval >= Constants.minimumContinuationPlaybackTime,
              fullTimeInterval - timeInterval >= Constants.completedPlaybackThreshold else {
            return previousSessionRepo.removeSavedTimeInterval(for: fingerprint)
        }
        
        previousSessionRepo.saveTimeInterval(timeInterval, for: fingerprint)
    }
}
