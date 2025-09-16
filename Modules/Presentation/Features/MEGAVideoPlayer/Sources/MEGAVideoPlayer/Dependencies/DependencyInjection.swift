import MEGAPreference
import MEGASdk

public enum DependencyInjection {
    public static var sharedSdk: MEGASdk {
        get {
            guard let _sharedSdk else {
                if !isRunningTests {
                    assertionFailure("sharedSdk is not injected")
                }
                return .init()
            }

            return _sharedSdk
        }
        set { _sharedSdk = newValue }
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
    }

    private static nonisolated(unsafe) var _sharedSdk: MEGASdk?

    public static var streamingUseCase: some StreamingUseCaseProtocol {
        StreamingUseCase(
            repository: StreamingRepository(
                sdk: DependencyInjection.sharedSdk
            )
        )
    }

    public static var selectVideoPlayerOptionUseCase: some SelectVideoPlayerUseCaseProtocol {
        SelectVideoPlayerUseCase()
    }

    public static var playbackReporter: some PlaybackReporting {
        MEGALogPlaybackReporter()
    }
    
    public static var resumePlaybackPositionUseCase: some ResumePlaybackPositionUseCaseProtocol {
        ResumePlaybackPositionUseCase(
            preferenceUseCase: PreferenceUseCase.default
        )
    }
}
