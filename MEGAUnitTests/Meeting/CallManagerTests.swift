@testable import MEGA
import MEGADomain
import Testing

@Suite("CallsManager")
struct CallManagerTests {
    class Harness {
        let sut: CallsManager
        
        init() {
            sut = CallsManager()
        }
        
        func addCall(audioEnabled: Bool = true) {
            sut.addCall(
                CallActionSync(
                    chatRoom: .testEntity,
                    audioEnabled: audioEnabled
                ),
                withUUID: .testUUID
            )
        }
    }
    
    @Suite("Remove Call")
    struct RemoveCall {
        @Test("Removing call cleans storage")
        func removeCall_cleansStorage() {
            let harness = Harness()
            harness.addCall()
            harness.sut.removeCall(withUUID: .testUUID)
            #expect(harness.sut.call(forUUID: .testUUID) == nil)
        }
        
        @Test("Removing all calls cleans storage")
        func removeAllCalls_cleansStorage() {
            let harness = Harness()
            harness.addCall()
            harness.sut.removeAllCalls()
            #expect(harness.sut.call(forUUID: .testUUID) == nil)
        }
    }
    
    @Suite("Update Call")
    struct UpdateCall {
        @Test("Mute/unmute call", arguments: [false, true])
        func updateCall_muteUnmuteCall(audioEnabled: Bool) throws {
            let harness = Harness()
            harness.addCall(audioEnabled: audioEnabled)
            let mute = audioEnabled
            harness.sut.updateCall(withUUID: .testUUID, muted: mute)
            let callMuted = try #require(harness.sut.call(forUUID: .testUUID))
            #expect(callMuted.audioEnabled == !audioEnabled)
        }
        
        @Test("End for all")
        func updateCall_updatesEndForAll() throws {
            let harness = Harness()
            harness.addCall()
            harness.sut.updateEndForAllCall(withUUID: .testUUID)
            let call = try #require(harness.sut.call(forUUID: .testUUID))
            #expect(call.endForAll == true)
        }
    }
    
    @Test("Start call and read data")
    func addCall_thenReadingCallData() throws {
        let harness = Harness()
        harness.addCall()
        let call = try #require(harness.sut.call(forUUID: .testUUID))
        #expect(call.chatRoom == .testEntity)
    }
}
