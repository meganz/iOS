extension ShareViewController {
    @objc func configSharedSecureFingerprintFlag() {
        let secureFlagManager = SharedSecureFingerprintManager()
        let isSecure = secureFlagManager.secureFingerprintVerification
        secureFlagManager.setSecureFingerprintFlag(isSecure)
    }
}
