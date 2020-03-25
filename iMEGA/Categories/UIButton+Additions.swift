
extension UIButton {
    
    // MARK: - Buttons
    
    @objc func mnz_setupBasic(_ traitCollection: UITraitCollection) {
        backgroundColor = UIColor.mnz_basicButton(for: traitCollection)
        setTitleColor(UIColor.mnz_turquoise(for: traitCollection), for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupPrimary(_ traitCollection: UITraitCollection) {
        backgroundColor = UIColor.mnz_turquoise(for: traitCollection)
        setTitleColor(UIColor.white, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupDestructive(_ traitCollection: UITraitCollection) {
        backgroundColor = UIColor.mnz_background()
        setTitleColor(UIColor.mnz_redMain(for: traitCollection), for: UIControl.State.normal)
        
        setupLayer()
    }
    
    // MARK: - Private
    
    private func setupLayer() {
        layer.cornerRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 3
        layer.shadowColor = UIColor.black.cgColor
    }
}
