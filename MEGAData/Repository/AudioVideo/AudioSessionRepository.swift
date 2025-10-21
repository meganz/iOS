import Combine
import MEGADomain

final class AudioSessionRepository: AudioSessionRepositoryProtocol {
    static let newRepo = AudioSessionRepository(audioSession: .sharedInstance())
    
    private let audioSession: AVAudioSession
    
    var isBluetoothAudioRouteAvailable: Bool {
        audioSession.isBluetoothAudioRouteAvailable
    }
    
    var currentSelectedAudioPort: AudioPort {
        guard let portType = audioSession.currentRoute.outputs.first?.portType else {
            return .unknown
        }
        
        return switch portType {
        case .builtInReceiver: .builtInReceiver
        case .builtInSpeaker: .builtInSpeaker
        case .headphones: .headphones
        default: .other
        }
    }
    
    public init(audioSession: AVAudioSession) {
        self.audioSession = audioSession
    }
    
    private func executeAction(functionName: StaticString = #function, action: () throws -> Void) {
        do {
            try action()
        } catch {
            MEGALogError("[AudioSession] \(functionName) error: \(error.localizedDescription)")
        }
    }
    
    func configureDefaultAudioSession() {
        executeAction {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
    
    func configureCallAudioSession() {
        executeAction {
            let isSpeakerEnabled = currentSelectedAudioPort == .builtInSpeaker
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetoothHFP, .allowBluetoothA2DP, .mixWithOthers])
            if isSpeakerEnabled {
                try audioSession.overrideOutputAudioPort(.speaker)
            }
            try audioSession.setActive(true)
        }
    }
    
    func configureAudioPlayerAudioSession() {
        executeAction {
            try audioSession.setCategory(.playback, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
        }
    }
    
    func configureChatDefaultAudioPlayer() {
        executeAction {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothHFP, .defaultToSpeaker])
        }
    }
    
    func configureAudioRecorderAudioSession(isPlayerAlive: Bool, ) {
        executeAction {
            if isPlayerAlive {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            }
            try audioSession.setActive(true)
        }
    }
    
    func configureVideoAudioSession() {
        executeAction {
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        }
    }
    
    func enableLoudSpeaker() {
        MEGALogDebug("[AudioSession] enabling loud speaker")
        executeAction {
            try audioSession.overrideOutputAudioPort(.speaker)
        }
    }
    
    func disableLoudSpeaker() {
        MEGALogDebug("[AudioSession] disable loud speaker")
        executeAction {
            try audioSession.overrideOutputAudioPort(.none)
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
}

extension AudioPort {
    var avAudioSessionPort: AVAudioSession.Port? {
        return switch self {
        case .builtInSpeaker: .builtInSpeaker
        case .builtInReceiver: .builtInReceiver
        case .headphones: .headphones
        default: nil
        }
    }
}

extension AVAudioSession.RouteChangeReason {
    func toAudioSessionRouteChangedReason() -> AudioSessionRouteChangedReason? {
        return switch self {
        case .unknown: .unknown
        case .newDeviceAvailable: .newDeviceAvailable
        case .oldDeviceUnavailable: .oldDeviceUnavailable
        case .categoryChange: .categoryChange
        case .override: .override
        case .wakeFromSleep: .wakeFromSleep
        case .noSuitableRouteForCategory: .noSuitableRouteForCategory
        case .routeConfigurationChange: .routeConfigurationChange
        @unknown default: nil
        }
    }
}

extension AVAudioSessionPortDescription {
    func toAudioPort() -> AudioPort {
        return switch self.portType {
        case .builtInSpeaker: .builtInSpeaker
        case .builtInReceiver: .builtInReceiver
        case .headphones: .headphones
        default: .other
        }
    }
}
