extension InputView {
    @objc func updateAppearance() {
        topSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        bottomSeparatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        iconImageView?.tintColor = UIColor.mnz_secondaryGray(for: traitCollection)
        topLabel?.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        inputTextField?.textColor = UIColor.label
        
        if backgroundColor != nil && !isUsingDefaultBackgroundColor {
            backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        } else {
            backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
            isUsingDefaultBackgroundColor = true
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
}
