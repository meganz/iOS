@testable import Chat
import MEGADomainMock
import MEGAPresentationMock
import Testing

@MainActor
@Suite("HangOrEndCallViewModel")
struct HangOrEndCallViewModelTests {
    
    @MainActor
    struct Harness {
        var sut: HangOrEndCallViewModel
        var router: MockHangOrEndCallRouter
        var tracker: MockTracker
        
        init() {
            self.router = MockHangOrEndCallRouter()
            self.tracker = MockTracker()
            self.sut = HangOrEndCallViewModel(
                router: router,
                tracker: tracker
            )
        }
    }

    @Test("Leave call calls router")
    func leaveCall() {
        let harness = Harness()
        harness.sut.leaveCall()
        #expect(harness.router.leaveCall_calledTimes == 1)
    }
    
    @Test("End call calls router")
    func endCallForAll() {
        let harness = Harness()
        harness.sut.endCallForAll()
        #expect(harness.router.endCallForAllTimes == 1)
    }

}

final class MockHangOrEndCallRouter: HangOrEndCallRouting {
    
    private(set) var leaveCall_calledTimes = 0
    private(set) var endCallForAllTimes = 0
    
    func leaveCall() {
        leaveCall_calledTimes += 1
    }
    
    func endCallForAll() {
        endCallForAllTimes += 1
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)?) {}
}
