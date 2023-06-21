import Foundation
import MEGADomain

public final class PlaybackContinuationUseCaseFeatureFlagProxy: PlaybackContinuationUseCaseProtocol {
    
    private let useCase: any PlaybackContinuationUseCaseProtocol
    private let isFeatureFlagEnabled: () -> Bool
    
    init(
        useCase: any PlaybackContinuationUseCaseProtocol,
        isFeatureFlagEnabled: @escaping () -> Bool
    ) {
        self.useCase = useCase
        self.isFeatureFlagEnabled = isFeatureFlagEnabled
    }
    
    public func status(for fingerprint: FingerprintEntity) -> PlaybackContinuationStatusEntity {
        guard isFeatureFlagEnabled() else { return .startFromBeginning }
        
        return useCase.status(for: fingerprint)
    }
    
    public func setPreference(to preferenceStatus: PlaybackContinuationPreferenceStatusEntity) {
        guard isFeatureFlagEnabled() else { return }
        
        return useCase.setPreference(to: preferenceStatus)
    }
    
    public func playbackStopped(
        for fingerprint: FingerprintEntity,
        on timeInterval: TimeInterval,
        outOf fullTimeInterval: TimeInterval
    ) {
        guard isFeatureFlagEnabled() else { return }
        
        useCase.playbackStopped(for: fingerprint, on: timeInterval, outOf: fullTimeInterval)
    }
}
