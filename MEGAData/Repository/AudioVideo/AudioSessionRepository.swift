
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
        
        MEGALogDebug("AudioSession: current selected audio port is \(portType)")
        switch portType {
        case .builtInReceiver: return .builtInReceiver
        case .builtInSpeaker: return .builtInSpeaker
        case .headphones: return .headphones
        default: return .other
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
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch (let error) {
            MEGALogError("[AudioPlayer] AVAudioSession Error: \(error.localizedDescription)")
        }
    }
    
    
    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        MEGALogDebug("AudioSession: enabling loud speaker")
        do {
            try audioSession.overrideOutputAudioPort(.speaker)
            completion(.success(()))
        } catch {
            MEGALogError("Error enabling the loudspeaker \(error.localizedDescription)")
            completion(.failure(.generic))
        }
    }
    
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        MEGALogDebug("AudioSession: disable loud speaker")
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
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        MEGALogDebug("AudioSession: session route changed \(notification) with current selected port \(currentSelectedAudioPort)")
        
        if let handler = routeChanged, let audioSessionRouteChangeReason = reason.toAudioSessionRouteChangedReason() {
            handler(audioSessionRouteChangeReason)
        } else {
            MEGALogDebug("Either the handler is nil or the audioSessionRouteChangeReason is nil")
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

extension AVAudioSession.RouteChangeReason {
    func toAudioSessionRouteChangedReason() -> AudioSessionRouteChangedReason? {
        switch self {
        case .unknown: return .unknown
        case .newDeviceAvailable: return .newDeviceAvailable
        case .oldDeviceUnavailable: return .oldDeviceUnavailable
        case .categoryChange: return .categoryChange
        case .override: return .override
        case .wakeFromSleep: return .wakeFromSleep
        case .noSuitableRouteForCategory: return .noSuitableRouteForCategory
        case .routeConfigurationChange: return .routeConfigurationChange
        @unknown default: return nil
        }
    }
}
