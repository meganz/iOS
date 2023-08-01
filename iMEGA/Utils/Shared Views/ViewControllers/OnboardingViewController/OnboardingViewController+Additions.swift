import MEGASDKRepo

extension OnboardingViewController {
    @objc func setSecureFingerprintVerificationTapToToggle() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(toggleSecureFingerprintFlag))
        tapGestureRecognizer.numberOfTapsRequired = 5
        scrollView?.isUserInteractionEnabled = true
        scrollView?.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func toggleSecureFingerprintFlag() {
        let manager = SharedSecureFingerprintManager()
        manager.onToggleSecureFingerprintFlag = {
            let adapter = ToggleSecureFingerprintFlagUIAlertAdapter(manager: manager)
            adapter.showAlert()
        }
        manager.toggleSecureFingerprintFlag()
    }

    @objc func setupTertiaryButton() {
        tertiaryButton?.titleLabel?.numberOfLines = 0
        tertiaryButton?.titleLabel?.textAlignment = .center
    }
}
