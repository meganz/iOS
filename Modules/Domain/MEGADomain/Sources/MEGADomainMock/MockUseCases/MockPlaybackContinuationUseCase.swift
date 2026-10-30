import Foundation
import MEGADomain

public final class MockPlaybackContinuationUseCase: PlaybackContinuationUseCaseProtocol, @unchecked Sendable {
    public var _status: PlaybackContinuationStatusEntity
    public var _savedPlaybackTime: TimeInterval?
    public private(set) var setPreference_Calls = [PlaybackContinuationPreferenceStatusEntity]()
    public private(set) var removeSavedPlaybackPosition_Calls = [FingerprintEntity]()
    
    public init(status: PlaybackContinuationStatusEntity = .startFromBeginning) {
        _status = status
    }
    
    public func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        _status
    }
    
    public func savedPlaybackTime(for fingerprint: FingerprintEntity) -> TimeInterval? {
        _savedPlaybackTime
    }
    
    public func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {
        setPreference_Calls.append(preferenceStatus)
    }
    
    public var playbackStoppedOutcome: PlaybackContinuationOutcomeEntity = .removed

    @discardableResult
    public func playbackStopped(for fingerprint: FingerprintEntity, on timeInterval: TimeInterval, outOf fullTimeInterval: TimeInterval) -> PlaybackContinuationOutcomeEntity {
        playbackStoppedOutcome
    }

    public func removeSavedPlaybackPosition(for fingerprint: FingerprintEntity) {
        removeSavedPlaybackPosition_Calls.append(fingerprint)
    }
}
