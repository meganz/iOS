
import Foundation

class ExtensionAppearanceManager: NSObject {
    
    @objc class func setupAppearance(_ traitCollection: UITraitCollection) {
        setupNavigationAppearance(traitCollection)
        
        //To tint the color of the prompt.
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).textColor = UIColor.mnz_label()
        
        UISearchBar.appearance().isTranslucent = false
        UISearchBar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.mnz_background()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.mnz_label()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        
        let segmentedControlFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.font: segmentedControlFont], for: .normal)
        
        let barButtonItemFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barButtonItemFont], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        UITextField.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UIProgressView.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UITableView.appearance().backgroundColor = UIColor.mnz_background()
        UIButton.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        UITableViewCell.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UICollectionView.appearance().backgroundColor = UIColor.mnz_background()
        UIButton.appearance(whenContainedInInstancesOf: [UICollectionViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        
        UIToolbar.appearance().barTintColor = UIColor.mnz_mainBars(for: traitCollection)
        UIToolbar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        self.setupThirdPartyAppereance(traitCollection)
    }
    
    class func setupThirdPartyAppereance(_ traitCollection: UITraitCollection) {
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.custom)
        SVProgressHUD.setMinimumSize(CGSize(width: 180, height: 100))
        SVProgressHUD.setRingThickness(2)
        SVProgressHUD.setRingRadius(16)
        SVProgressHUD.setRingNoTextRadius(16)
        SVProgressHUD.setCornerRadius(8)
        SVProgressHUD.setShadowOffset(CGSize(width: 0, height: 1))
        SVProgressHUD.setShadowOpacity(0.15)
        SVProgressHUD.setShadowRadius(8)
        SVProgressHUD.setShadowColor(UIColor.black)
        if #available(iOS 13.0, *) {
            SVProgressHUD.setHudViewCustomBlurEffect(UIBlurEffect.init(style: UIBlurEffect.Style.systemChromeMaterial))
        }
        SVProgressHUD.setFont(UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold))
        SVProgressHUD.setForegroundColor(UIColor.mnz_primaryGray(for: traitCollection))
        SVProgressHUD.setForegroundImageColor(UIColor.mnz_primaryGray(for: traitCollection))
        SVProgressHUD.setBackgroundColor(UIColor.mnz_background())
        SVProgressHUD.setHapticsEnabled(true)
        
        SVProgressHUD.setSuccessImage(UIImage(named: "hudSuccess")!)
        SVProgressHUD.setErrorImage(UIImage(named: "hudError")!)
    }
    
    /// Reload the current view that was configured using UIAppearance
    @objc class func invalidateViews() {
        let currentView = UIApplication.shared.delegate?.window??.rootViewController?.view
        let superview = currentView?.superview
        currentView?.removeFromSuperview()
        superview?.addSubview(currentView!)
        
        UIApplication.shared.windows.forEach { window in
            window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            window.rootViewController?.children.forEach({ $0.setNeedsStatusBarAppearanceUpdate() })

            window.subviews.forEach { view in
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }
    }
    
    // MARK: - Private
    
    private class func setupNavigationAppearance(_ traitCollection: UITraitCollection) {
        let navigationBarFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        UINavigationBar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.font: navigationBarFont, NSAttributedString.Key.foregroundColor: UIColor.mnz_label()!]
        
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
            
            navigationBarAppearance.shadowImage = nil
            navigationBarAppearance.shadowColor = nil
            
            let backArrowImage = UIImage(named: "backArrow")
            navigationBarAppearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
            
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        } else {
            UINavigationBar.appearance().barTintColor = UIColor.mnz_mainBars(for: traitCollection)
            UINavigationBar.appearance().backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
            
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
            UINavigationBar.appearance().shadowImage = UIImage()
            
            UINavigationBar.appearance().backIndicatorImage = UIImage(named: "backArrow")
            UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "backArrow")
        }
    }
}
