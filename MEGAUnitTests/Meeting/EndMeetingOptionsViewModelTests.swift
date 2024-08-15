@testable import MEGA
import XCTest

class EndMeetingOptionsViewModelTests: XCTestCase {

    @MainActor func testAction_onLeave() {
        let router = MockEndMeetingOptionsRouter()
        let viewModel = EndMeetingOptionsViewModel(router: router)
        test(viewModel: viewModel, action: .onLeave, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
        XCTAssert(router.showJoinMega_calledTimes == 1)
    }
    
    @MainActor func testAction_onCancel() {
        let router = MockEndMeetingOptionsRouter()
        let viewModel = EndMeetingOptionsViewModel(router: router)
        test(viewModel: viewModel, action: .onCancel, expectedCommands: [])
        XCTAssert(router.dismiss_calledTimes == 1)
    }

}

final class MockEndMeetingOptionsRouter: EndMeetingOptionsRouting {
    var dismiss_calledTimes = 0
    var showJoinMega_calledTimes = 0
    
    func dismiss(completion: @escaping () -> Void) {
        dismiss_calledTimes += 1
        completion()
    }
    
    func showJoinMega() {
        showJoinMega_calledTimes += 1
    }
}
