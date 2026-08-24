import MEGAPreference

public protocol VideoPlaybackLoopUseCaseProtocol: Sendable {
    /// The loop/repeat state the user last selected, or `false` when they never changed it
    var isLoopEnabled: Bool { get }

    /// Persists the loop/repeat state so it is restored on the next player launch
    func setLoopEnabled(_ enabled: Bool)
}

public struct VideoPlaybackLoopUseCase: VideoPlaybackLoopUseCaseProtocol {

    private enum PreferenceKey: String, PreferenceKeyProtocol {
        case videoPlayerIsLoopEnabled
    }

    @PreferenceWrapper(key: PreferenceKey.videoPlayerIsLoopEnabled, defaultValue: false)
    private var isLoopEnabledPreference: Bool

    public init(
        preferenceUseCase: some PreferenceUseCaseProtocol
    ) {
        $isLoopEnabledPreference.useCase = preferenceUseCase
    }

    public var isLoopEnabled: Bool {
        isLoopEnabledPreference
    }

    public func setLoopEnabled(_ enabled: Bool) {
        isLoopEnabledPreference = enabled
    }
}
