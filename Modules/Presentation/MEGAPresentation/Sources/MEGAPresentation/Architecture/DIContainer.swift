import MEGADomain
import MEGAData

public enum DIContainer {
    public static var authUseCase: any AuthUseCaseProtocol {
        AuthUseCase(
            repo: AuthRepository.newRepo,
            credentialRepo: CredentialRepository.newRepo
        )
    }
}

// MARK: - Audio Playback Continuation

public extension DIContainer {
    static func playbackContinuationUseCase(
        isFeatureFlagEnabled: @escaping () -> Bool
    ) -> any PlaybackContinuationUseCaseProtocol {
        PlaybackContinuationUseCaseFeatureFlagProxy(
            useCase: PlaybackContinuationUseCase.shared,
            isFeatureFlagEnabled: isFeatureFlagEnabled
        )
    }
}

extension PlaybackContinuationUseCase where T == PreviousPlaybackSessionRepository {
    /// We need to keep a single instance of this use case because we want to keep user's playback continuation preference.
    /// This preference only lives until the app is killed thus it shouldn't be kept in a local persistence framework like UserDefaults.
    static var shared = PlaybackContinuationUseCase(
        previousSessionRepo: PreviousPlaybackSessionRepository.newRepo
    )
}
