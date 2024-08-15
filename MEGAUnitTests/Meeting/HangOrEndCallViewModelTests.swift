@testable import MEGA
import MEGADomainMock
import XCTest

class HangOrEndCallViewModelTests: XCTestCase {

    @MainActor func testAction_leaveCall() {
        let router = MockHangOrEndCallRouter()
        let viewModel = HangOrEndCallViewModel(router: router,
                                               analyticsEventUseCase: MockAnalyticsEventUseCase())
        test(viewModel: viewModel, action: .leaveCall, expectedCommands: [])
        XCTAssert(router.leaveCall_calledTimes == 1)
    }
    
    @MainActor func testAction_endCallForAll() {
        let router = MockHangOrEndCallRouter()
        let statsUseCase = MockAnalyticsEventUseCase()
        let viewModel = HangOrEndCallViewModel(router: router, analyticsEventUseCase: statsUseCase)
        test(viewModel: viewModel, action: .endCallForAll, expectedCommands: [])
        XCTAssert(router.endCallForAllTimes == 1)
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
