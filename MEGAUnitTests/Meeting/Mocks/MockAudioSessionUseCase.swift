
@testable import MEGA

final class MockAudioSessionUseCase: AudioSessionUseCaseProtocol {
    var isBluetoothAudioRouteAvailable: Bool = false
    var currentSelectedAudioPort: AudioPort = .builtInReceiver
    var audioPortOutput: AudioPort = .builtInReceiver
    var enableLoudSpeaker_calledTimes = 0
    var disableLoudSpeaker_calledTimes = 0

    func enableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        enableLoudSpeaker_calledTimes += 1
    }
    
    func disableLoudSpeaker(completion: @escaping (Result<Void, AudioSessionError>) -> Void) {
        disableLoudSpeaker_calledTimes += 1
    }
    
    func isOutputFrom(port: AudioPort) -> Bool {
        return port == audioPortOutput
    }
    
    func routeChanged(handler: ((AudioSessionRouteChangedReason) -> Void)?) { }
}
