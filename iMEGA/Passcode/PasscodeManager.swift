protocol PasscodeManagerProtocol {
    func shouldPresentPasscodeViewLater() -> Bool
    func closePasscodeView()
    func disablePasscodeWhenApplicationEntersBackground()
}

struct PasscodeManager: PasscodeManagerProtocol {
    func shouldPresentPasscodeViewLater() -> Bool {
        UIApplication.shared.applicationState == .background || LTHPasscodeViewController.sharedUser().isLockscreenPresent()
    }
    
    func closePasscodeView() {
        LTHPasscodeViewController.close()
    }
    
    func disablePasscodeWhenApplicationEntersBackground() {
        LTHPasscodeViewController.sharedUser().disablePasscodeWhenApplicationEntersBackground()
    }
}
