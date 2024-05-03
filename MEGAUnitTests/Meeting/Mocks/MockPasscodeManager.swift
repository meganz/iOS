@testable import MEGA

final class MockPasscodeManager: PasscodeManagerProtocol {
    var shouldPresentPasscodeViewLater_CalledTimes = 0
    var closePasscodeView_CalledTimes = 0
    var disablePasscodeWhenApplicationEntersBackground_CalledTimes = 0

    func shouldPresentPasscodeViewLater() -> Bool {
        shouldPresentPasscodeViewLater_CalledTimes += 1
        return true
    }
    
    func closePasscodeView() {
        closePasscodeView_CalledTimes += 1
    }
    
    func disablePasscodeWhenApplicationEntersBackground() {
        disablePasscodeWhenApplicationEntersBackground_CalledTimes += 1
    }
}
