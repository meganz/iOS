extension PasswordView {
    @objc func updateAppearance() {
        let currentTraitCollection = self.traitCollection
        topSeparatorView.backgroundColor = UIColor.mnz_separator(for: currentTraitCollection)
        bottomSeparatorView.backgroundColor = UIColor.mnz_separator(for: currentTraitCollection)
            
        leftImageView.tintColor = UIColor.mnz_secondaryGray(for: currentTraitCollection)
        
        topLabel.textColor = UIColor.mnz_secondaryGray(for: currentTraitCollection)
        passwordTextField.textColor = UIColor.label
        
        if backgroundColor != nil && !self.isUsingDefaultBackgroundColor {
            backgroundColor = UIColor.mnz_tertiaryBackground(currentTraitCollection)
        } else {
            backgroundColor = UIColor.mnz_secondaryBackground(for: currentTraitCollection)
            isUsingDefaultBackgroundColor = true
        }
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
}
