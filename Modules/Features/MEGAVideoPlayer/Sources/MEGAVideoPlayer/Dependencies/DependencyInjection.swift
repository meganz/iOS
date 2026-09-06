import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGASwift

public enum DependencyInjection {
    public static var streamingUseCase: some StreamingUseCaseProtocol {
        StreamingUseCase(
            repository: StreamingRepository.newRepo
        )
    }

    public static var localFileURLProvider: @Sendable (any PlayableNode) -> URL? {
        get { localFileURLProviderStorage.wrappedValue }
        set { localFileURLProviderStorage.mutate { $0 = newValue } }
    }

    private static let localFileURLProviderStorage = Atomic<@Sendable (any PlayableNode) -> URL?>(
        wrappedValue: { _ in nil }
    )

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

    public static var videoPlaybackLoopUseCase: some VideoPlaybackLoopUseCaseProtocol {
        VideoPlaybackLoopUseCase(
            preferenceUseCase: PreferenceUseCase.default
        )
    }

    public static var videoNodesUseCase: some VideoNodesUseCaseProtocol {
        VideoNodesUseCase(
            repo: VideoNodesRepository.newRepo
        )
    }
}
