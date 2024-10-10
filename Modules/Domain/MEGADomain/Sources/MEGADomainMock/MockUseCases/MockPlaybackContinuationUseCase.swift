import Foundation
import MEGADomain

public final class MockPlaybackContinuationUseCase: PlaybackContinuationUseCaseProtocol, @unchecked Sendable {
    public var _status: PlaybackContinuationStatusEntity
    public private(set) var setPreference_Calls = [PlaybackContinuationPreferenceStatusEntity]()
    
    public init(status: PlaybackContinuationStatusEntity = .startFromBeginning) {
        _status = status
    }
    
    public func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        _status
    }
    
    public func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {
        setPreference_Calls.append(preferenceStatus)
    }
    
    public func playbackStopped(for fingerprint: FingerprintEntity, on timeInterval: TimeInterval, outOf fullTimeInterval: TimeInterval) {
        
    }
}
