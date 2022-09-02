
public protocol AudioSessionRepositoryProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    func configureAudioSession()
    var routeChanged: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)? { get set }
    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void)
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionErrorEntity>) -> Void)
    func isOutputFrom(port: AudioPort) -> Bool
}
