
public protocol AudioSessionRepositoryProtocol {
    var isBluetoothAudioRouteAvailable: Bool { get }
    var currentSelectedAudioPort: AudioPort { get }
    var routeChanged: ((_ reason: AudioSessionRouteChangedReason, _ previousAudioPort: AudioPort?) -> Void)? { get set }
    func configureDefaultAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureMeetingAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureAudioPlayerAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureChatDefaultAudioPlayer(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureAudioRecorderAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureInstantSoundsAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func configureVideoAudioSession(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func setSpeaker(enabled: Bool, completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func enableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func disableLoudSpeaker(completion: ((Result<Void, AudioSessionErrorEntity>) -> Void)?)
    func isOutputFrom(port: AudioPort) -> Bool
}
