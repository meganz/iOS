import MEGADomain

public final class MockAudioSessionUseCase: AudioSessionUseCaseProtocol {
    public var isBluetoothAudioRouteAvailable: Bool
    public var currentSelectedAudioPort: AudioPort
    private let audioPortOutput: AudioPort
    public var enableLoudSpeaker_calledTimes: Int
    public var disableLoudSpeaker_calledTimes: Int
    private var configureAudioSession_calledTimes: Int
    
    public init(isBluetoothAudioRouteAvailable: Bool = false, currentSelectedAudioPort: AudioPort = .builtInReceiver, audioPortOutput: AudioPort = .builtInReceiver, enableLoudSpeaker_calledTimes: Int = 0, disableLoudSpeaker_calledTimes: Int = 0, configureAudioSession_calledTimes: Int = 0) {
        self.isBluetoothAudioRouteAvailable = isBluetoothAudioRouteAvailable
        self.currentSelectedAudioPort = currentSelectedAudioPort
        self.audioPortOutput = audioPortOutput
        self.enableLoudSpeaker_calledTimes = enableLoudSpeaker_calledTimes
        self.disableLoudSpeaker_calledTimes = disableLoudSpeaker_calledTimes
        self.configureAudioSession_calledTimes = configureAudioSession_calledTimes
    }

    public func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void) {
        enableLoudSpeaker_calledTimes += 1
    }
    
    public func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void) {
        disableLoudSpeaker_calledTimes += 1
    }
    
    public func isOutputFrom(port: AudioPort) -> Bool {
        return port == audioPortOutput
    }
    
    public func routeChanged(handler: ((AudioSessionRouteChangedReason, AudioPort?) -> Void)?) {}
    
    public func configureAudioSession() {
        configureAudioSession_calledTimes += 1
    }
}
