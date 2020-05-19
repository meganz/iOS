
import Foundation

class AppearanceManager: NSObject {
    
    @objc class func setupAppearance(_ traitCollection: UITraitCollection) {
        
        setupNavigationAppearance(traitCollection)
        
        let navigationBarFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).titleTextAttributes = [NSAttributedString.Key.font: navigationBarFont, NSAttributedString.Key.foregroundColor: UIColor.mnz_label()!]
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).backgroundColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        UILabel.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).textColor = UIColor.mnz_label()
        
        //QLPreviewDocument
        UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).titleTextAttributes = [NSAttributedString.Key.font: navigationBarFont,  NSAttributedString.Key.foregroundColor: UIColor.mnz_label()!]
        UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UILabel.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).textColor = UIColor.mnz_primaryGray(for: traitCollection)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGAAssetsPickerController.self]).titleTextAttributes = [NSAttributedString.Key.font: navigationBarFont, NSAttributedString.Key.foregroundColor: UIColor.mnz_label()!]
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGAAssetsPickerController.self]).barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGAAssetsPickerController.self]).backgroundColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [MEGAAssetsPickerController.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        UISearchBar.appearance().isTranslucent = false
        UISearchBar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.mnz_background()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.mnz_label()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        
        let segmentedControlFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.font: segmentedControlFont], for: .normal)
        
        UISwitch.appearance().onTintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        let barButtonItemFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barButtonItemFont], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        UITextField.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UITextView.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UIProgressView.appearance().backgroundColor = UIColor.clear
        UIProgressView.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        if #available(iOS 10, *) {
            UITabBar.appearance().unselectedItemTintColor = UIColor.mnz_primaryGray(for: traitCollection)
        }
        UITabBar.appearance().tintColor = UIColor.mnz_redMain(for: traitCollection)
        UITabBar.appearance().barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        
        UITableView.appearance().backgroundColor = UIColor.mnz_background()
        UITableView.appearance().separatorColor = UIColor.mnz_separatorColor(for: traitCollection)
        UIButton.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        UITableViewCell.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UICollectionView.appearance().backgroundColor = UIColor.mnz_background()
        UIButton.appearance(whenContainedInInstancesOf: [UICollectionViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        
        self.setupActivityIndicatorAppearance(traitCollection)
        
        self.setupToolbar(traitCollection)
        
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
        SVProgressHUD.setBackgroundColor(UIColor.mnz_secondaryBackground(for: traitCollection))
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
        if #available(iOS 13.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor.mnz_mainBarsColor(for: traitCollection)
            
            navigationBarAppearance.shadowImage = nil
            navigationBarAppearance.shadowColor = nil
            
            let backArrowImage = UIImage(named: "backArrow")
            navigationBarAppearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
            
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        } else {
            UINavigationBar.appearance().barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
            UINavigationBar.appearance().backgroundColor = UIColor.mnz_mainBarsColor(for: traitCollection)
            
            UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
            UINavigationBar.appearance().shadowImage = UIImage()
            
            UINavigationBar.appearance().backIndicatorImage = UIImage(named: "backArrow")
            UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "backArrow")
        }
    }
    
    private class func setupActivityIndicatorAppearance(_ traitCollection: UITraitCollection) {
        if #available(iOS 13.0, *) {
            UIActivityIndicatorView.appearance().style = .medium
            UIActivityIndicatorView.appearance().color = (traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? UIColor.white : UIColor.mnz_primaryGray(for: traitCollection)
        } else {
            UIActivityIndicatorView.appearance().style = .gray
            UIActivityIndicatorView.appearance().color = UIColor.mnz_primaryGray(for: traitCollection)
        }
    }
    
    private class func setupToolbar(_ traitCollection: UITraitCollection) {
        if #available(iOS 13, *) {
            let toolbarAppearance = UIToolbarAppearance.init()
            toolbarAppearance.configureWithDefaultBackground()
            toolbarAppearance.backgroundColor = UIColor.mnz_mainBarsColor(for: traitCollection)
            UIToolbar.appearance().standardAppearance = toolbarAppearance
        } else {
            UIToolbar.appearance().backgroundColor = UIColor.mnz_mainBarsColor(for: traitCollection)
            UIToolbar.appearance().barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
            UIToolbar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        }
    }
}
