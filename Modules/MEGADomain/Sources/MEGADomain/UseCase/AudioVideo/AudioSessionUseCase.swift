
public protocol AudioSessionUseCaseProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    func configureAudioSession()
    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void)
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void)
    func isOutputFrom(port: AudioPort) -> Bool
    func routeChanged(handler: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)?)
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
    
    public func configureAudioSession() {
        audioSessionRepository.configureAudioSession()
    }
    
    public func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void) {
        audioSessionRepository.enableLoudSpeaker(completion: completion)
    }
    
    public func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void) {
        audioSessionRepository.disableLoudSpeaker(completion: completion)
    }
    
    public func isOutputFrom(port: AudioPort) -> Bool {
        audioSessionRepository.isOutputFrom(port: port)
    }
    
    public func routeChanged(handler: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)?) {
        audioSessionRepository.routeChanged = handler
    }
}
