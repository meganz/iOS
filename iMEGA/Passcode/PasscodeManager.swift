import MEGADomain
import MEGAL10n

protocol PasscodeManagerProtocol {
    /// Disables the passcode if it is enabled for properly manage calls.
    ///
    /// This function is responsible for ensuring that the passcode mechanisms does not interfere with
    /// actions from the MEGA system when triggered from background state, i.e. starting a call from Contacts app.
    func disablePassCodeIfNeeded()
    
    /// Enables the passcode if it was disabled for an user action when it is completed or required.
    ///
    /// This function is responsible for ensuring that the passcode mechanism is not overpassed after disabling temporally it, by some user action triggered from background state.
    func showPassCodeIfNeeded()
}

struct PasscodeManager: PasscodeManagerProtocol {
    @PreferenceWrapper(key: .presentPasscodeLater, defaultValue: false, useCase: PreferenceUseCase.default)
    var presentPasscodeLater: Bool
    
    func disablePassCodeIfNeeded() {
        if shouldPresentPasscodeViewLater() {
            presentPasscodeLater = true
            closePasscodeView()
        }
    }
    
    func showPassCodeIfNeeded() {
        if presentPasscodeLater &&
            LTHPasscodeViewController.doesPasscodeExist() {
            presentPasscodeLater = false
            LTHPasscodeViewController
                .sharedUser()
                .showLockScreenOver(UIApplication.mnz_presentingViewController().view, withAnimation: true, withLogout: true, andLogoutTitle: Strings.Localizable.logoutLabel)
        }
    }
    
    // MARK: - Private
    private func shouldPresentPasscodeViewLater() -> Bool {
        UIApplication.shared.applicationState == .background || LTHPasscodeViewController.sharedUser().isLockscreenPresent()
    }
    
    private func closePasscodeView() {
        LTHPasscodeViewController.close()
    }
    
    private func disablePasscodeWhenApplicationEntersBackground() {
        LTHPasscodeViewController.sharedUser().disablePasscodeWhenApplicationEntersBackground()
    }
}
