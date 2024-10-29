import MEGADesignToken

extension PasswordReminderViewController {
    @objc func makePasswordReminderViewModel() -> PasswordReminderViewModel {
        PasswordReminderViewModel()
    }
    
    @objc func requestStopAudioPlayerSession() {
        let streamingInfoUseCase = StreamingInfoUseCase()
        if AudioPlayerManager.shared.isPlayerAlive() {
            streamingInfoUseCase.stopServer()
        }
    }
    
    @objc func updateAppearance() {
        alphaView?.backgroundColor = TokenColors.Background.page
        backgroundView?.backgroundColor = TokenColors.Background.page

        titleLabel?.textColor = TokenColors.Text.primary
        descriptionLabel?.textColor = TokenColors.Text.primary
        switchInfoLabel?.textColor = TokenColors.Text.primary

        doNotShowMeAgainView?.backgroundColor = TokenColors.Background.page
        doNotShowMeAgainTopSeparatorView?.backgroundColor = TokenColors.Border.strong
        doNotShowMeAgainBottomSeparatorView?.backgroundColor = TokenColors.Border.strong

        testPasswordButton?.setTitleColor(TokenColors.Text.accent, for: .normal)
        testPasswordButton?.backgroundColor = TokenColors.Button.secondary

        dismissButton?.backgroundColor = .clear
        dismissButton?.setTitleColor(TokenColors.Text.primary, for: .normal)
        
        backupKeyButton?.mnz_setupPrimary(traitCollection)
    }
    
    // MARK: - Analytics Events
    
    @objc func trackScreenView() {
        viewModel.trackEvent(.onViewDidLoad)
    }
    
    @objc func trackCloseButtonTap() {
        viewModel.trackEvent(.didTapClose)
    }
    
    @objc func trackTestPasswordButtonTap() {
        viewModel.trackEvent(.didTapTestPassword)
    }
    
    @objc func trackExportRecoveryKeyButtonTap() {
        viewModel.trackEvent(.didTapExportRecoveryKey)
    }
    
    @objc func trackExportRecoveryKeyCopyOKAlertButtonTap() {
        viewModel.trackEvent(.didTapExportRecoveryKeyCopyOKAlert)
    }
    
    @objc func trackDismissButtonTap() {
        if isLoggingOut {
            viewModel.trackEvent(.didTapProceedToLogout)
        }
    }
}
