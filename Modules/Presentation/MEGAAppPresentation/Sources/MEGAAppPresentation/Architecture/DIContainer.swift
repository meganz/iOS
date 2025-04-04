import MEGAAnalyticsDomain
import MEGAAnalyticsiOS
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

public enum DIContainer {
    public static var authUseCase: any AuthUseCaseProtocol {
        AuthUseCase(
            repo: AuthRepository.newRepo,
            credentialRepo: CredentialRepository.newRepo
        )
    }
    
    public static var rubbishBinUseCase: some RubbishBinUseCaseProtocol {
        RubbishBinUseCase(rubbishBinRepository: RubbishBinRepository.newRepo)
    }
    
    public static var abTestProvider: some ABTestProviderProtocol {
        ABTestProvider()
    }
    
    public static var remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol {
        RemoteFeatureFlagUseCase(
            repository: RemoteFeatureFlagRepository.newRepo
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
    static let shared = PlaybackContinuationUseCase(
        previousSessionRepo: PreviousPlaybackSessionRepository.newRepo
    )
}

// MARK: - Analytics

public extension DIContainer {
    static let tracker: some AnalyticsTracking = Tracker.shared
}

extension Tracker {
    static let shared: Tracker = {
        Tracker(
            viewIdProvider: viewIdProvider,
            appIdentifier: AppIdentifier(id: 0),
            eventSender: eventSender
        )
    }()
    
    static let viewIdProvider = ViewIdProviderAdapter(
        viewIdUseCase: DIContainer.viewIDUseCase
    )
    
    static let eventSender = EventSenderAdapter(
        analyticsUseCase: DIContainer.analyticsUseCase
    )
}

extension DIContainer {
    static var analyticsUseCase: some AnalyticsUseCaseProtocol {
        AnalyticsUseCase(analyticsRepo: AnalyticsRepository.newRepo)
    }
    
    static var viewIDUseCase: some ViewIDUseCaseProtocol {
        ViewIDUseCase(viewIdRepo: ViewIDRepository.newRepo)
    }
}
