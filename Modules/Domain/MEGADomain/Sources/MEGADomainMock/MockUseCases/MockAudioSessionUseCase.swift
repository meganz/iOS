import Combine
import MEGADomain

public final class MockAudioSessionUseCase: AudioSessionUseCaseProtocol {
    public var isBluetoothAudioRouteAvailable: Bool
    public var currentSelectedAudioPort: AudioPort
    private let audioPortOutput: AudioPort
    public var enableLoudSpeaker_calledTimes: Int
    public var disableLoudSpeaker_calledTimes: Int
    private var configureDefaultAudioSession_calledTimes: Int
    private var configureCallAudioSession_calledTimes: Int
    private var configureAudioPlayerAudioSession_calledTimes: Int
    private var configureChatDefaultAudioPlayerAudioSession_calledTimes: Int
    private var configureAudioRecorderAudioSession_calledTimes: Int
    private var configureVideoAudioSession_calledTimes: Int
    private let onAudioSessionRouteChangeSubject: PassthroughSubject<AudioSessionRouteChangedReason, Never>
    
    public init(
        isBluetoothAudioRouteAvailable: Bool = false,
        currentSelectedAudioPort: AudioPort = .builtInReceiver,
        audioPortOutput: AudioPort = .builtInReceiver,
        enableLoudSpeaker_calledTimes: Int = 0,
        disableLoudSpeaker_calledTimes: Int = 0,
        configureDefaultAudioSession_calledTimes: Int = 0,
        configureCallAudioSession_calledTimes: Int = 0,
        configureAudioPlayerAudioSession_calledTimes: Int = 0,
        configureChatDefaultAudioPlayerAudioSession_calledTimes: Int = 0,
        configureAudioRecorderAudioSession_calledTimes: Int = 0,
        configureVideoAudioSession_calledTimes: Int = 0,
        onAudioSessionRouteChangeSubject: PassthroughSubject<AudioSessionRouteChangedReason, Never> = .init()
    ) {
        self.isBluetoothAudioRouteAvailable = isBluetoothAudioRouteAvailable
        self.currentSelectedAudioPort = currentSelectedAudioPort
        self.audioPortOutput = audioPortOutput
        self.enableLoudSpeaker_calledTimes = enableLoudSpeaker_calledTimes
        self.disableLoudSpeaker_calledTimes = disableLoudSpeaker_calledTimes
        self.configureDefaultAudioSession_calledTimes = configureDefaultAudioSession_calledTimes
        self.configureCallAudioSession_calledTimes = configureCallAudioSession_calledTimes
        self.configureAudioPlayerAudioSession_calledTimes = configureAudioPlayerAudioSession_calledTimes
        self.configureChatDefaultAudioPlayerAudioSession_calledTimes = configureChatDefaultAudioPlayerAudioSession_calledTimes
        self.configureAudioRecorderAudioSession_calledTimes = configureAudioRecorderAudioSession_calledTimes
        self.configureVideoAudioSession_calledTimes = configureVideoAudioSession_calledTimes
        self.onAudioSessionRouteChangeSubject = onAudioSessionRouteChangeSubject
    }
    
    public func setSpeaker(enabled: Bool, completion: ((Result<Void, MEGADomain.AudioSessionErrorEntity>) -> Void)?) {
        if enabled {
            enableLoudSpeaker_calledTimes += 1
        } else {
            disableLoudSpeaker_calledTimes += 1
        }
    }

    public func enableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        enableLoudSpeaker_calledTimes += 1
    }
    
    public func disableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        disableLoudSpeaker_calledTimes += 1
    }
    
    public func isOutputFrom(port: AudioPort) -> Bool {
        return port == audioPortOutput
    }
    
    public func routeChanged(handler: ((AudioSessionRouteChangedReason, AudioPort?) -> Void)?) {}
    
    public func configureDefaultAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        configureDefaultAudioSession_calledTimes += 1
    }
    
    public func configureCallAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        configureCallAudioSession_calledTimes += 1
    }
    
    public func configureAudioPlayerAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        configureAudioPlayerAudioSession_calledTimes += 1
    }
    
    public func configureChatDefaultAudioPlayer(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        configureChatDefaultAudioPlayerAudioSession_calledTimes += 1
    }
    
    public func configureAudioRecorderAudioSession(isPlayerAlive: Bool, completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        configureAudioRecorderAudioSession_calledTimes += 1
    }
    
    public func configureVideoAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        configureVideoAudioSession_calledTimes += 1
    }
    
    public func onAudioSessionRouteChange() -> AnyPublisher<AudioSessionRouteChangedReason, Never> {
        onAudioSessionRouteChangeSubject
            .eraseToAnyPublisher()
    }
}
