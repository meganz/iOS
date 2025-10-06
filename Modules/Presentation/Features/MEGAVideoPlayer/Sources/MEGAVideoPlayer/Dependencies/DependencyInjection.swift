import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

public enum DependencyInjection {
    public static var streamingUseCase: some StreamingUseCaseProtocol {
        StreamingUseCase(
            repository: StreamingRepository.newRepo
        )
    }

    public static var playbackReporter: some PlaybackReporting {
        MEGALogPlaybackReporter()
    }

    public static var analyticsTracker: some AnalyticsTracking {
        DIContainer.tracker
    }

    public static var resumePlaybackPositionUseCase: some ResumePlaybackPositionUseCaseProtocol {
        ResumePlaybackPositionUseCase(
            preferenceUseCase: PreferenceUseCase.default
        )
    }

    public static var videoNodesUseCase: some VideoNodesUseCaseProtocol {
        VideoNodesUseCase(
            repo: VideoNodesRepository.newRepo
        )
    }
}
