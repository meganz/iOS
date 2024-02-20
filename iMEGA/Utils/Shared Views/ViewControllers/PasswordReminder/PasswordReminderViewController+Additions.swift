import MEGADesignToken

extension PasswordReminderViewController {
    
    @objc func requestStopAudioPlayerSession() {
        let streamingInfoUseCase = StreamingInfoUseCase()
        if AudioPlayerManager.shared.isPlayerAlive() {
            streamingInfoUseCase.stopServer()
        }
    }
    
    @objc func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            alphaView.backgroundColor = TokenColors.Background.page
            backgroundView.backgroundColor = TokenColors.Background.page
            
            titleLabel.textColor = TokenColors.Text.primary
            descriptionLabel.textColor = TokenColors.Text.primary
            switchInfoLabel.textColor = TokenColors.Text.primary
            
            doNotShowMeAgainView.backgroundColor = TokenColors.Background.page
            doNotShowMeAgainTopSeparatorView.backgroundColor = TokenColors.Border.strong
            doNotShowMeAgainBottomSeparatorView.backgroundColor = TokenColors.Border.strong
            
            testPasswordButton.setTitleColor(TokenColors.Text.accent, for: .normal)
            testPasswordButton.backgroundColor = TokenColors.Button.secondary
            
            dismissButton.backgroundColor = .clear
            dismissButton.setTitleColor(TokenColors.Text.primary, for: .normal)
        } else {
            backgroundView.backgroundColor = UIColor.systemBackground
            
            descriptionLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
            
            doNotShowMeAgainView.backgroundColor = UIColor.mnz_backgroundElevated(traitCollection)
            doNotShowMeAgainTopSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
            doNotShowMeAgainBottomSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
            
            testPasswordButton.mnz_setupBasic(traitCollection)
            dismissButton.mnz_setupCancel(traitCollection)
        }
        
        backupKeyButton.mnz_setupPrimary(traitCollection)
    }

}
