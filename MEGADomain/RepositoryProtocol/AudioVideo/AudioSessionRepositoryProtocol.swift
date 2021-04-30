
enum AudioSessionRouteChangedReason {
    case generic
    case override
    case categoryChange
}

enum AudioPort {
    case unknown
    case builtInReceiver
    case builtInSpeaker
    case headphones
}

protocol AudioSessionRepositoryProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    var routeChanged: ((AudioSessionRouteChangedReason) -> Void)? { get set }
    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void)
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void)
    func isOutputFrom(port: AudioPort) -> Bool
}
