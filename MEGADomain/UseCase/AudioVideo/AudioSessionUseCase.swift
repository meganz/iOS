
protocol AudioSessionUseCaseProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    func configureAudioSession()
    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void)
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void)
    func isOutputFrom(port: AudioPort) -> Bool
    func routeChanged(handler: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)?)
}

final class AudioSessionUseCase : AudioSessionUseCaseProtocol {
    private var audioSessionRepository: AudioSessionRepositoryProtocol
    
    var isBluetoothAudioRouteAvailable: Bool {
        audioSessionRepository.isBluetoothAudioRouteAvailable
    }
    
    var currentSelectedAudioPort: AudioPort {
        audioSessionRepository.currentSelectedAudioPort
    }
    
    init(audioSessionRepository: AudioSessionRepositoryProtocol) {
        self.audioSessionRepository = audioSessionRepository
    }
    
    func configureAudioSession() {
        audioSessionRepository.configureAudioSession()
    }
    
    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        audioSessionRepository.enableLoudSpeaker(completion: completion)
    }
    
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        audioSessionRepository.disableLoudSpeaker(completion: completion)
    }
    
    func isOutputFrom(port: AudioPort) -> Bool {
        audioSessionRepository.isOutputFrom(port: port)
    }
    
    func routeChanged(handler: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)?) {
        audioSessionRepository.routeChanged = handler
    }
}
