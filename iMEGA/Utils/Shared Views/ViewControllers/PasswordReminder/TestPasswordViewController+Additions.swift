extension TestPasswordViewController {
    @objc func makeTestPasswordViewModel() -> TestPasswordViewModel {
        TestPasswordViewModel()
    }
    
    // MARK: - Analytics events
    @objc func trackScreenView() {
        viewModel.trackEvent(.onViewDidLoad)
    }
    
    @objc func trackConfirmButtonTap() {
        viewModel.trackEvent(.didTapConfirm)
    }
    
    @objc func trackWrongPasswordDisplayed() {
        viewModel.trackEvent(.didShowWrongPassword)
    }
    
    @objc func trackPasswordAcceptedDisplayed() {
        viewModel.trackEvent(.didShowPasswordAccepted)
    }
    
    @objc func trackExportRecoveryKeyButtonTap() {
        viewModel.trackEvent(.didTapExportRecoveryKey)
    }
    
    @objc func trackExportRecoveryKeyCopyOKAlertButtonTap() {
        viewModel.trackEvent(.didTapExportRecoveryKeyCopyOKAlert)
    }
    
    @objc func trackProceedToLogoutButtonTap() {
        guard isLoggingOut else { return }
        viewModel.trackEvent(.didTapProceedToLogout)
    }
}
