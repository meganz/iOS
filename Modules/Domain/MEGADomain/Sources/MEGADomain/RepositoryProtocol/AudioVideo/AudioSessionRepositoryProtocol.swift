import Combine

public protocol AudioSessionRepositoryProtocol: RepositoryProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    var routeChanged: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)? { get set }
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
