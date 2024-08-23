@testable import MEGA

final class MockEnterMeetingLinkRouter: EnterMeetingLinkRouting {
    
    var showLinkErrorCalled = false

    func showLinkError() {
        showLinkErrorCalled = true
    }
}
