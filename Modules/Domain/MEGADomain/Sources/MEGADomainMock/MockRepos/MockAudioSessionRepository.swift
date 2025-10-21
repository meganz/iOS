import Combine
import Foundation
import MEGADomain

public final class MockAudioSessionRepository: AudioSessionRepositoryProtocol, @unchecked Sendable {
    public static let newRepo = MockAudioSessionRepository()
    
    public var isBluetoothAudioRouteAvailableStub = false
    public var currentSelectedAudioPortStub: AudioPort = .unknown
    private let routeChangeSubject = PassthroughSubject<AudioSessionRouteChangedReason, Never>()
    
    public private(set) var configureDefaultCalledTimes = 0
    public private(set) var configureCallCalledTimes = 0
    public private(set) var configureAudioPlayerCalledTimes = 0
    public private(set) var configureChatDefaultPlayerCalledTimes = 0
    public private(set) var configureRecorderCalledTimes = 0
    public private(set) var configureVideoCalledTimes = 0
    public private(set) var enableLoudSpeakerCalledTimes = 0
    public private(set) var disableLoudSpeakerCalledTimes = 0
    public private(set) var isOutputFromCalledTimes = 0
    public private(set) var isOutputFromLastPort: AudioPort?
    
    public var isBluetoothAudioRouteAvailable: Bool { isBluetoothAudioRouteAvailableStub }
    public var currentSelectedAudioPort: AudioPort { currentSelectedAudioPortStub }

    public func configureDefaultAudioSession() { configureDefaultCalledTimes += 1 }
    public func configureCallAudioSession() { configureCallCalledTimes += 1 }
    public func configureAudioPlayerAudioSession() { configureAudioPlayerCalledTimes += 1 }
    public func configureChatDefaultAudioPlayer() { configureChatDefaultPlayerCalledTimes += 1 }
    public func configureAudioRecorderAudioSession(isPlayerAlive: Bool) { configureRecorderCalledTimes += 1 }
    public func configureVideoAudioSession() { configureVideoCalledTimes += 1 }

    public func enableLoudSpeaker() { enableLoudSpeakerCalledTimes += 1 }
    public func disableLoudSpeaker() { disableLoudSpeakerCalledTimes += 1 }
    
    public init() {}

    public func isOutputFrom(port: AudioPort) -> Bool {
        isOutputFromCalledTimes += 1
        isOutputFromLastPort = port
        return port == currentSelectedAudioPortStub
    }

    public func onAudioSessionRouteChange() -> AnyPublisher<AudioSessionRouteChangedReason, Never> {
        routeChangeSubject.eraseToAnyPublisher()
    }
    
    public func emitRouteChange(_ reason: AudioSessionRouteChangedReason) {
        routeChangeSubject.send(reason)
    }
}
