import MEGASDKRepo

extension ShareViewController {
    @objc func configSharedSecureFingerprintFlag() {
        let secureFlagManager = SharedSecureFingerprintManager()
        let isSecure = secureFlagManager.secureFingerprintVerification
        Task {
            await secureFlagManager.setSecureFingerprintFlag(isSecure)
        }
        
    }
}
