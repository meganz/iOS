
@objc enum MEGACustomButtonStyle: Int {
    case none
    case basic
    case primary
    case primaryDisabled
    case destructive
    case cancel
    case delete
}

extension UIButton {
    
    @objc func mnz_setup(_ style: MEGACustomButtonStyle, traitCollection: UITraitCollection) {
        switch style {
        case .basic:
            mnz_setupBasic(traitCollection)
            
        case .primary:
            mnz_setupPrimary(traitCollection)
            
        case .primaryDisabled:
            mnz_setupPrimary_disabled(traitCollection)
            
        case .destructive:
            mnz_setupDestructive(traitCollection)
            
        case .cancel:
            mnz_setupCancel(traitCollection)
        
        case .delete:
            mnz_setupDelete(traitCollection)
            
        default:
            mnz_setupBasic(traitCollection)
        }
    }
    
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
    
    @objc func mnz_setupPrimary_disabled(_ traitCollection: UITraitCollection) {
        var darkMode = false
        if traitCollection.userInterfaceStyle == .dark {
            darkMode = true
        }
        backgroundColor = UIColor.mnz_turquoise(for: traitCollection).withAlphaComponent(darkMode ? 0.2 : 0.3)
        setTitleColor(UIColor.white.withAlphaComponent(darkMode ? 0.2 : 0.7), for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupDestructive(_ traitCollection: UITraitCollection) {
        backgroundColor = UIColor.mnz_basicButton(for: traitCollection)
        setTitleColor(UIColor.mnz_red(for: traitCollection), for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupDelete(_ traitCollection: UITraitCollection) {
        backgroundColor = UIColor.mnz_red(for: traitCollection)
        setTitleColor(UIColor.white, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupCancel(_ traitCollection: UITraitCollection) {
        backgroundColor = UIColor.clear
        setTitleColor(UIColor.mnz_secondaryGray(for: traitCollection), for: UIControl.State.normal)
    }
    
    @objc func mnz_clearSetup() {
        backgroundColor = UIColor.clear
        
        removeLayer()
    }
    
    @objc func mnz_alignImageAndTitleVertically(padding: CGFloat) {
        guard let imageView = imageView,
              let titleLabel = titleLabel else {
                  return
              }
        
        let imageSize = imageView.frame.size
        let titleSize = titleLabel.frame.size
        let totalHeight = imageSize.height + titleSize.height + padding

        let imageTopValue = totalHeight - imageSize.height
        imageEdgeInsets = UIEdgeInsets(
            top: imageTopValue * -1,
            left: 0,
            bottom: 0,
            right: titleSize.width * -1
        )

        let titleBottomValue = totalHeight - titleSize.height
        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageSize.width * -1,
            bottom: titleBottomValue * -1,
            right: 0
        )
    }
    
    // MARK: - Private
    
    private func setupLayer() {
        layer.cornerRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 3
        layer.shadowColor = UIColor.black.cgColor
    }
    
    private func removeLayer() {
        layer.cornerRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowColor = UIColor.clear.cgColor
    }
}
