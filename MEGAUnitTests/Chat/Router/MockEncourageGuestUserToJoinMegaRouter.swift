@testable import MEGA

final class MockEncourageGuestUserToJoinMegaRouter: EncourageGuestUserToJoinMegaRouting {
    private(set) var dismissCallCount = 0
    private(set) var createAccountCallCount = 0
    
    func dismiss(completion: (() -> Void)?) {
        dismissCallCount += 1
    }
    
    func createAccount() {
        createAccountCallCount += 1
    }
}
