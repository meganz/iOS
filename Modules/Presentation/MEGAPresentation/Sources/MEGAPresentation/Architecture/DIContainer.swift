import MEGAAnalyticsDomain
import MEGAAnalyticsiOS
import MEGADomain
import MEGASDKRepo

public enum DIContainer {
    public static var authUseCase: any AuthUseCaseProtocol {
        AuthUseCase(
            repo: AuthRepository.newRepo,
            credentialRepo: CredentialRepository.newRepo
        )
    }
    
    public static var featureFlagProvider: some FeatureFlagProviderProtocol {
        FeatureFlagProvider(
            useCase: FeatureFlagUseCase(
                repository: FeatureFlagRepository.newRepo
            )
        )
    }
}

// MARK: - Audio Playback Continuation

public extension DIContainer {
    static var playbackContinuationUseCase: any PlaybackContinuationUseCaseProtocol {
        PlaybackContinuationUseCase.shared
    }
}

extension PlaybackContinuationUseCase where T == PreviousPlaybackSessionRepository {
    /// We need to keep a single instance of this use case because we want to keep user's playback continuation preference.
    /// This preference only lives until the app is killed thus it shouldn't be kept in a local persistence framework like UserDefaults.
    static var shared = PlaybackContinuationUseCase(
        previousSessionRepo: PreviousPlaybackSessionRepository.newRepo
    )
}

// MARK: - Analytics

public extension DIContainer {
    static var tracker: some AnalyticsTracking = Tracker.shared
}

extension Tracker {
    static var shared: Tracker = {
        Tracker(
            viewIdProvider: ViewIdProviderAdapter(
                viewIdUseCase: DIContainer.viewIDUseCase
            ),
            eventSender: EventSenderAdapter(
                analyticsUseCase: DIContainer.analyticsUseCase
            )
        )
    }()
}

extension DIContainer {
    static var analyticsUseCase: some AnalyticsUseCaseProtocol {
        AnalyticsUseCase(analyticsRepo: AnalyticsRepository.newRepo)
    }
    
    static var viewIDUseCase: some ViewIDUseCaseProtocol {
        ViewIDUseCase(viewIdRepo: ViewIDRepository.newRepo)
    }
}
