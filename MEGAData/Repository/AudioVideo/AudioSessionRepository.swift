import Combine
import MEGADomain

final class AudioSessionRepository: AudioSessionRepositoryProtocol {
    
    static let newRepo = AudioSessionRepository(audioSession: .sharedInstance())
    
    private let audioSession: AVAudioSession
    
    var routeChanged: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)?
    
    var isBluetoothAudioRouteAvailable: Bool {
        audioSession.isBluetoothAudioRouteAvailable
    }
    
    var currentSelectedAudioPort: AudioPort {
        guard let portType = audioSession.currentRoute.outputs.first?.portType else {
            return .unknown
        }
        
        switch portType {
        case .builtInReceiver: return .builtInReceiver
        case .builtInSpeaker: return .builtInSpeaker
        case .headphones: return .headphones
        default: return .other
        }
    }
    
    // wrapping in async to make sure it's executed in the background thread
    // and does not cause app hang
    private func asyncCurrentSelectedAudioPort() async -> AudioPort {
        currentSelectedAudioPort
    }
    
    public init(audioSession: AVAudioSession) {
        self.audioSession = audioSession
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    func configureDefaultAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            completion?(.success)
        } catch {
            MEGALogError("[AudioSession] configureDefaultAudioSession Error: \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func configureCallAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        do {
            let isSpeakerEnabled = currentSelectedAudioPort == .builtInSpeaker
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .allowBluetoothA2DP, .mixWithOthers])
            if isSpeakerEnabled {
                try audioSession.overrideOutputAudioPort(.speaker)
            }
            try audioSession.setActive(true)
            completion?(.success)
        } catch {
            MEGALogError("[AudioSession] configureCallAudioSession Error: \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func configureAudioPlayerAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            completion?(.success)
        } catch {
            MEGALogError("[AudioSession] configureAudioPlayerAudioSession Error: \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func configureChatDefaultAudioPlayer(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothHFP, .defaultToSpeaker])
            completion?(.success)
        } catch {
            MEGALogInfo("[AudioSession] configureChatDefaultAudioPlayerAudioSession Error: \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func configureAudioRecorderAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        do {
            if AudioPlayerManager.shared.isPlayerAlive() {
                AudioPlayerManager.shared.audioInterruptionDidStart()
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            }
            try AVAudioSession.sharedInstance().setActive(true)
            completion?(.success)
        } catch {
            MEGALogError("[AudioSession] configureAudioRecorderAudioSession Error: \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func configureVideoAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            completion?(.success)
        } catch {
            MEGALogError("[AudioSession] configureVideoAudioSession Error: \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func enableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        MEGALogDebug("AudioSession: enabling loud speaker")
        do {
            try audioSession.overrideOutputAudioPort(.speaker)
            completion?(.success)
        } catch {
            MEGALogError("Error enabling the loudspeaker \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func disableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?) {
        MEGALogDebug("AudioSession: disable loud speaker")
        do {
            try audioSession.overrideOutputAudioPort(.none)
            completion?(.success)
        } catch {
            MEGALogError("Error disabling the loudspeaker \(error.localizedDescription)")
            completion?(.failure(.generic))
        }
    }
    
    func isOutputFrom(port: AudioPort) -> Bool {
        guard let avAudioSessionPort = port.avAudioSessionPort else {
            return false
        }
        
        return audioSession.isOutputEqualToPortType(avAudioSessionPort)
    }
    
    func onAudioSessionRouteChange() -> AnyPublisher<AudioSessionRouteChangedReason, Never> {
        NotificationCenter.default
            .publisher(for: AVAudioSession.routeChangeNotification)
            .compactMap { notification -> AudioSessionRouteChangedReason? in
                guard let userInfo = notification.userInfo,
                      let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                    return nil
                }
                return reason.toAudioSessionRouteChangedReason()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private methods
    
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
        
        let previousAudioPort: AudioPort?
        if
            reason == .categoryChange,
            let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
            previousAudioPort = previousRoute.outputs.first?.toAudioPort()
        } else {
            previousAudioPort = nil
        }
        
        if let handler = routeChanged,
           let previousAudioPort,
           let audioSessionRouteChangeReason = reason.toAudioSessionRouteChangedReason() {
            handler(audioSessionRouteChangeReason, previousAudioPort)
        } else {
            MEGALogDebug("AudioSession: Either the handler is nil or the audioSessionRouteChangeReason is nil")
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

extension AVAudioSessionPortDescription {
    func toAudioPort() -> AudioPort {
        switch self.portType {
        case .builtInSpeaker:
            return .builtInSpeaker
        case .builtInReceiver:
            return .builtInReceiver
        case .headphones:
            return .headphones
        default:
            return .other
        }
    }
}
