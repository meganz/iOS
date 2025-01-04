@testable import MEGA

final class MockRecoveryKeyViewRouter: RecoveryKeyViewRouting {
    private(set) var showSecurityLink_calledTimes = 0
    private(set) var presentView_calledTimes = 0
    private let _recoveryKeyViewController: UIViewController?
    
    nonisolated init(recoveryKeyViewController: UIViewController? = nil) {
        _recoveryKeyViewController = recoveryKeyViewController
    }
    
    var recoveryKeyViewController: UIViewController? {
        _recoveryKeyViewController
    }
    
    func showSecurityLink() {
        showSecurityLink_calledTimes += 1
    }
    
    func presentView() {
        presentView_calledTimes += 1
    }
}
