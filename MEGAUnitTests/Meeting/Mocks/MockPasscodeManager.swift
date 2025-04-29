@testable import MEGA

final class MockPasscodeManager: PasscodeManagerProtocol {
    var disablePassCodeIfNeeded_CalledTimes = 0
    var showPassCodeIfNeeded_CalledTimes = 0
    
    func disablePassCodeIfNeeded() {
        disablePassCodeIfNeeded_CalledTimes += 1
    }
    
    func showPassCodeIfNeeded() {
        showPassCodeIfNeeded_CalledTimes += 1
    }
}
