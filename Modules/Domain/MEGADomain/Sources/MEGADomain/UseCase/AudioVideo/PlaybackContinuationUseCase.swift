import Foundation
import MEGASwift

/// Whether a playback position was saved for resuming, or removed.
public enum PlaybackContinuationOutcomeEntity: Sendable, Equatable {
    case saved
    case removed
}

public protocol PlaybackContinuationUseCaseProtocol: Sendable {
    func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity
    func savedPlaybackTime(for fingerprint: FingerprintEntity) -> TimeInterval?
    func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity)
    @discardableResult
    func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) -> PlaybackContinuationOutcomeEntity
    func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity)
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

        /// The minimum playback time when the home revamp phase two feature flag is enabled.
        public static var minimumContinuationPlaybackTimeRevamp: TimeInterval { 15.seconds }
    }

    private let currentPreference: Atomic<PlaybackContinuationPreferenceStatusEntity?> = Atomic(wrappedValue: nil)

    private let previousSessionRepo: T
    private let minimumPlaybackTime: TimeInterval

    public init(
        previousSessionRepo: T,
        minimumPlaybackTime: TimeInterval = Constants.minimumContinuationPlaybackTime
    ) {
        self.previousSessionRepo = previousSessionRepo
        self.minimumPlaybackTime = minimumPlaybackTime
    }
    
    public func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        guard let previousTimeInterval = savedPlaybackTime(for: fingerprint) else {
            return .startFromBeginning
        }
        
        guard let currentPreference = currentPreference.wrappedValue else { return .displayDialog(playbackTime: previousTimeInterval) }
        
        switch currentPreference {
        case .restartFromBeginning: return .startFromBeginning
        case .resumePreviousSession: return .resumeSession(playbackTime: previousTimeInterval)
        }
    }
    
    public func savedPlaybackTime(for fingerprint: FingerprintEntity) -> TimeInterval? {
        guard let previousTimeInterval = previousSessionRepo.timeInterval(for: fingerprint),
              previousTimeInterval >= minimumPlaybackTime else {
            return nil
        }
        return previousTimeInterval
    }
    
    public func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {
        currentPreference.mutate { $0 = preferenceStatus }
    }
    
    @discardableResult
    public func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) -> PlaybackContinuationOutcomeEntity {
        guard timeInterval >= minimumPlaybackTime,
              fullTimeInterval - timeInterval >= Constants.completedPlaybackThreshold else {
            previousSessionRepo.removeSavedTimeInterval(for: fingerprint)
            return .removed
        }
        
        previousSessionRepo.saveTimeInterval(timeInterval, for: fingerprint)
        return .saved
    }

    public func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity) {
        previousSessionRepo.removeSavedTimeInterval(for: fingerprint)
    }
}
