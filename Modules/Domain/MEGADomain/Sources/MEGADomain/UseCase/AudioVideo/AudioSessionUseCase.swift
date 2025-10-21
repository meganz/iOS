import Combine

public protocol AudioSessionUseCaseProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    func configureDefaultAudioSession()
    func configureCallAudioSession()
    func configureAudioPlayerAudioSession()
    func configureChatDefaultAudioPlayer()
    func configureAudioRecorderAudioSession(isPlayerAlive: Bool, )
    func configureVideoAudioSession()
    func isOutputFrom(port: AudioPort) -> Bool
    func enableLoudSpeaker()
    func disableLoudSpeaker()
    func onAudioSessionRouteChange() -> AnyPublisher<AudioSessionRouteChangedReason, Never>
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
    
    public func configureDefaultAudioSession() {
        audioSessionRepository.configureDefaultAudioSession()
    }
    
    public func configureCallAudioSession() {
        audioSessionRepository.configureCallAudioSession()
    }
    
    public func configureAudioPlayerAudioSession() {
        audioSessionRepository.configureAudioPlayerAudioSession()
    }
    
    public func configureChatDefaultAudioPlayer() {
        audioSessionRepository.configureChatDefaultAudioPlayer()
    }
    
    public func configureAudioRecorderAudioSession(isPlayerAlive: Bool, ) {
        audioSessionRepository.configureAudioRecorderAudioSession(isPlayerAlive: isPlayerAlive, )
    }
    
    public func configureVideoAudioSession() {
        audioSessionRepository.configureVideoAudioSession()
    }
    
    public func enableLoudSpeaker() {
        audioSessionRepository.enableLoudSpeaker()
    }
    
    public func disableLoudSpeaker() {
        audioSessionRepository.disableLoudSpeaker()
    }
    
    public func isOutputFrom(port: AudioPort) -> Bool {
        audioSessionRepository.isOutputFrom(port: port)
    }
    
    // Change it to AsyncSequence once we drop iOS 14
    public func onAudioSessionRouteChange() -> AnyPublisher<AudioSessionRouteChangedReason, Never> {
        audioSessionRepository.onAudioSessionRouteChange()
    }
}
