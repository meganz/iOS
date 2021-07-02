
final class AudioSessionRepository: AudioSessionRepositoryProtocol {
    private let audioSession: AVAudioSession
    
    var routeChanged: ((AudioSessionRouteChangedReason) -> Void)?
    
    var isBluetoothAudioRouteAvailable: Bool {
        audioSession.mnz_isBluetoothAudioRouteAvailable
    }
    
    var currentSelectedAudioPort: AudioPort {
        guard let portType = audioSession.currentRoute.outputs.first?.portType else {
            return .unknown
        }
        
        switch portType {
        case .builtInReceiver: return .builtInReceiver
        case .builtInSpeaker: return .builtInSpeaker
        case .headphones: return .headphones
        default: return .unknown
        }
    }

    init(audioSession: AVAudioSession) {
        self.audioSession = audioSession
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    func configureAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [])
            try audioSession.setActive(true)
        } catch (let error) {
            MEGALogError("[AudioPlayer] AVAudioSession Error: \(error.localizedDescription)")
        }
    }
    
    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        do {
            try audioSession.overrideOutputAudioPort(.speaker)
            completion(.success(()))
        } catch {
            MEGALogError("Error enabling the loudspeaker \(error.localizedDescription)")
            completion(.failure(.generic))
        }
    }
    
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        do {
            try audioSession.overrideOutputAudioPort(.none)
            completion(.success(()))
        } catch {
            MEGALogError("Error disabling the loudspeaker \(error.localizedDescription)")
            completion(.failure(.generic))
        }
    }
    
    func isOutputFrom(port: AudioPort) -> Bool {
        guard let avAudioSessionPort = port.avAudioSessionPort else {
            return false
        }
        
        return audioSession.mnz_isOutputEqual(toPortType: avAudioSessionPort)
    }
    
    //MARK: - Private methods
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRouteChanged(notification:)),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    @objc private func sessionRouteChanged(notification: NSNotification) {
        guard let routeChangeReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt else {
            return
        }
        
        switch routeChangeReason {
        case AVAudioSession.RouteChangeReason.override.rawValue:
            routeChanged?(.override)
            
        case AVAudioSession.RouteChangeReason.categoryChange.rawValue:
            routeChanged?(.categoryChange)
            
        default:
            routeChanged?(.generic)
        }
    }
}

extension AudioPort {
    var avAudioSessionPort: AVAudioSession.Port? {
        switch self {
        case .builtInSpeaker:
            return .builtInSpeaker
        case .builtInReceiver:
            return .builtInReceiver
        case .headphones:
            return .headphones
        default:
            return nil
        }
    }
}
