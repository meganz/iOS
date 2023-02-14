import MEGADomain

@objc final class SharedSecureFingerprintManager: NSObject {
    
    @PreferenceWrapper(key: .secureFingerprintVerification, defaultValue: false, useCase: PreferenceUseCase.default)
    var secureFingerprintVerification: Bool
    
    @objc func setSecureFingerprintFlag(_ flag: Bool) {
        guard FeatureFlagProvider().isFeatureFlagEnabled(for: .mandatoryFingerprintVerification) else {
            return
        }
        MEGASdkManager.sharedMEGASdk().setShareSecureFlag(flag)
    }
    
    @objc func toggleSecureFingerprintFlag() {
        guard FeatureFlagProvider().isFeatureFlagEnabled(for: .mandatoryFingerprintVerification) else {
            return
        }
        
        let isSecure = !secureFingerprintVerification
        secureFingerprintVerification = isSecure
        setSecureFingerprintFlag(isSecure)
        
        let alertController = UIAlertController(title: nil,
                                                message: "Mandatory Contact Fingerprint Verification \(secureFingerprintStatus())",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""),
                                                style: .cancel,
                                                handler: nil))
        UIApplication.mnz_visibleViewController().present(alertController, animated: true)
    }
    
    @objc func secureFingerprintStatus() -> String {
        secureFingerprintVerification ? "ENABLED" : "DISABLED"
    }
}
