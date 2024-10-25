@testable import MEGA

final class MockRecoveryKeyViewRouter: RecoveryKeyViewRouting {
    private(set) var showSecurityLink_calledTimes = 0
    private let _recoveryKeyViewController: UIViewController?
    
    init(recoveryKeyViewController: UIViewController? = nil) {
        _recoveryKeyViewController = recoveryKeyViewController
    }
    
    var recoveryKeyViewController: UIViewController? {
        _recoveryKeyViewController
    }
    
    func showSecurityLink() {
        showSecurityLink_calledTimes += 1
    }
}
