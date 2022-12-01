
public protocol AudioSessionUseCaseProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    func configureDefaultAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureMeetingAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureAudioPlayerAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureChatDefaultAudioPlayer(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureAudioRecorderAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureInstantSoundsAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureVideoAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func isOutputFrom(port: AudioPort) -> Bool
    func setSpeaker(enabled: Bool, completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func enableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func disableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func routeChanged(handler: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)?)
}

extension AudioSessionUseCaseProtocol {
    public func configureDefaultAudioSession() {
        configureDefaultAudioSession(completion: nil)
    }
    
    public func configureMeetingAudioSession() {
        configureMeetingAudioSession(completion: nil)
    }
    
    public func configureAudioPlayerAudioSession() {
        configureAudioPlayerAudioSession(completion: nil)
    }
    
    public func configureChatDefaultAudioPlayer() {
        configureChatDefaultAudioPlayer(completion: nil)
    }
    
    public func configureAudioRecorderAudioSession() {
        configureAudioRecorderAudioSession(completion: nil)
    }
    
    public func configureInstantSoundsAudioSession() {
        configureInstantSoundsAudioSession(completion: nil)
    }
    
    public func configureVideoAudioSession() {
        configureVideoAudioSession(completion: nil)
    }
    
    public func setSpeaker(enabled: Bool) {
        setSpeaker(enabled: enabled, completion: nil)
    }
    
    public func enableLoudSpeaker() {
        enableLoudSpeaker(completion: nil)
    }
    
    public func disableLoudSpeaker() {
        disableLoudSpeaker(completion: nil)
    }
    
    public func routeChanged() {
        routeChanged(handler: nil)
    }
}

public final class AudioSessionUseCase<T: AudioSessionRepositoryProtocol>: AudioSessionUseCaseProtocol {
    private var audioSessionRepository: T
    
    public var isBluetoothAudioRouteAvailable: Bool {
        audioSessionRepository.isBluetoothAudioRouteAvailable
    }
    
    public var currentSelectedAudioPort: AudioPort {
        audioSessionRepository.currentSelectedAudioPort
    }
    
    public init(audioSessionRepository: T) {
        self.audioSessionRepository = audioSessionRepository
    }
    
    public func configureDefaultAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.configureDefaultAudioSession(completion: completion)
    }
    
    public func configureMeetingAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.configureMeetingAudioSession(completion: completion)
    }
    
    public func configureAudioPlayerAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.configureAudioPlayerAudioSession(completion: completion)
    }
    
    public func configureChatDefaultAudioPlayer(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.configureChatDefaultAudioPlayer(completion: completion)
    }
    
    public func configureAudioRecorderAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.configureAudioRecorderAudioSession(completion: completion)
    }
    
    public func configureInstantSoundsAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.configureInstantSoundsAudioSession(completion: completion)
    }
    
    public func configureVideoAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.configureVideoAudioSession(completion: completion)
    }
    
    public func setSpeaker(enabled: Bool, completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.setSpeaker(enabled: enabled, completion: completion)
    }
    
    public func enableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.enableLoudSpeaker(completion: completion)
    }
    
    public func disableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        audioSessionRepository.disableLoudSpeaker(completion: completion)
    }
    
    public func isOutputFrom(port: AudioPort) -> Bool {
        audioSessionRepository.isOutputFrom(port: port)
    }
    
    public func routeChanged(handler: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)?) {
        audioSessionRepository.routeChanged = handler
    }
}
