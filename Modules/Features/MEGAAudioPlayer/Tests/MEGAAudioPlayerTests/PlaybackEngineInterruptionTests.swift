import AVFoundation
import Foundation
@testable import MEGAAudioPlayer
import Testing

@Suite("PlaybackEngine audio interruption parsing")
struct PlaybackEngineInterruptionTests {

    // MARK: - interruptionType

    @Test
    func interruptionType_whenBeganPayload_returnsBegan() {
        let notification = makeInterruptionNotification(type: .began)
        #expect(PlaybackEngine.interruptionType(from: notification) == .began)
    }

    @Test
    func interruptionType_whenEndedPayload_returnsEnded() {
        let notification = makeInterruptionNotification(type: .ended)
        #expect(PlaybackEngine.interruptionType(from: notification) == .ended)
    }

    @Test
    func interruptionType_whenNoUserInfo_returnsNil() {
        let notification = Notification(name: AVAudioSession.interruptionNotification)
        #expect(PlaybackEngine.interruptionType(from: notification) == nil)
    }

    // MARK: - interruptionOptions

    @Test
    func interruptionOptions_whenShouldResumeSet_containsShouldResume() {
        let notification = makeInterruptionNotification(type: .ended, options: .shouldResume)
        #expect(PlaybackEngine.interruptionOptions(from: notification).contains(.shouldResume))
    }

    @Test
    func interruptionOptions_whenNoOptions_isEmpty() {
        let notification = makeInterruptionNotification(type: .ended)
        #expect(PlaybackEngine.interruptionOptions(from: notification).isEmpty)
    }

    // MARK: - Helpers

    private func makeInterruptionNotification(
        type: AVAudioSession.InterruptionType,
        options: AVAudioSession.InterruptionOptions? = nil
    ) -> Notification {
        var userInfo: [AnyHashable: Any] = [AVAudioSessionInterruptionTypeKey: type.rawValue]
        if let options {
            userInfo[AVAudioSessionInterruptionOptionKey] = options.rawValue
        }
        return Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: userInfo
        )
    }
}
