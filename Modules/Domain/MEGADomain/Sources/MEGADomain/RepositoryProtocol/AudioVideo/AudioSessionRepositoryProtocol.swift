import Combine

public protocol AudioSessionRepositoryProtocol: RepositoryProtocol, Sendable {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    func configureDefaultAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureCallAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureAudioPlayerAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureChatDefaultAudioPlayer(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureAudioRecorderAudioSession(isPlayerAlive: Bool, completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureVideoAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func enableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func disableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func isOutputFrom(port: AudioPort) -> Bool
    func onAudioSessionRouteChange() -> AnyPublisher<AudioSessionRouteChangedReason, Never>
}
