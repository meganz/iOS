import MEGAAssets
import MEGADesignToken

@objc enum MEGACustomButtonStyle: Int {
    case none
    case basic
    case primary
    case secondary
    case primaryDisabled
    case destructive
    case cancel
    case delete
}

extension UIButton {
    
    @objc func mnz_setup(_ style: MEGACustomButtonStyle) {
        switch style {
        case .basic:
            mnz_setupBasic()
            
        case .primary:
            mnz_setupPrimary()
            
        case .secondary:
            mnz_setupSecondary()
            
        case .primaryDisabled:
            mnz_setupPrimary_disabled()
            
        case .destructive:
            mnz_setupDestructive()
            
        case .cancel:
            mnz_setupCancel()
        
        case .delete:
            mnz_setupDelete()
            
        default:
            mnz_setupBasic()
        }
    }
    
    // MARK: - Buttons
    
    @objc func mnz_setupBasic(_ titleColor: UIColor? = nil) {
        backgroundColor = TokenColors.Button.secondary
        setTitleColor(titleColor ?? TokenColors.Support.success, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupPrimary() {
        backgroundColor = TokenColors.Button.primary
        setTitleColor(TokenColors.Text.inverse, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupSecondary() {
        backgroundColor = TokenColors.Button.secondary
        setTitleColor(TokenColors.Text.accent, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupPrimary_disabled() {
        backgroundColor = TokenColors.Button.disabled
        setTitleColor(TokenColors.Text.inverseAccent, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupDestructive() {
        backgroundColor = TokenColors.Button.secondary
        setTitleColor(TokenColors.Button.brand, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupDelete() {
        backgroundColor = TokenColors.Button.brand
        setTitleColor(MEGAAssets.UIColor.whiteFFFFFF, for: UIControl.State.normal)
        
        setupLayer()
    }
    
    @objc func mnz_setupCancel() {
        backgroundColor = UIColor.clear
        setTitleColor(TokenColors.Icon.secondary, for: UIControl.State.normal)
    }
    
    @objc func mnz_clearSetup() {
        backgroundColor = UIColor.clear
        
        removeLayer()
    }
    
    func setupLayer() {
        layer.cornerRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 3
        layer.shadowColor = MEGAAssets.UIColor.black000000.cgColor
    }
    
    // MARK: - Private
    
    private func removeLayer() {
        layer.cornerRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowColor = UIColor.clear.cgColor
    }
}
