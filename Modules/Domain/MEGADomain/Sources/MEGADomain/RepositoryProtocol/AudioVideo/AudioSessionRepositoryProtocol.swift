import Combine

public protocol AudioSessionRepositoryProtocol: RepositoryProtocol, Sendable {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    func configureDefaultAudioSession()
    func configureCallAudioSession()
    func configureAudioPlayerAudioSession()
    func configureChatDefaultAudioPlayer()
    func configureAudioRecorderAudioSession(isPlayerAlive: Bool, )
    func configureVideoAudioSession()
    func enableLoudSpeaker()
    func disableLoudSpeaker()
    func isOutputFrom(port: AudioPort) -> Bool
    func onAudioSessionRouteChange() -> AnyPublisher<AudioSessionRouteChangedReason, Never>
}
