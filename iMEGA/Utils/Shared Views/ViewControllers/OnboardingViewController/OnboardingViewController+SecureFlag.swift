extension OnboardingViewController {
    
    @objc func setSecureFingerprintVerificationTapToToggle() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(toggleSecureFingerprintFlag))
        tapGestureRecognizer.numberOfTapsRequired = 5
        scrollView?.isUserInteractionEnabled = true
        scrollView?.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func toggleSecureFingerprintFlag() {
        SharedSecureFingerprintManager().toggleSecureFingerprintFlag()
    }
}
