
import Foundation

class AppearanceManager: NSObject {
    
    @objc class func setupAppearance(_ traitCollection: UITraitCollection) {
        
        let navigationBarFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).titleTextAttributes = [NSAttributedString.Key.font: navigationBarFont, NSAttributedString.Key.foregroundColor: UIColor.mnz_label()!]
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).barStyle = UIBarStyle.default
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        UILabel.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).textColor = UIColor.mnz_label()
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGANavigationController.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "backArrow")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "backArrow")
        
        //QLPreviewDocument
        UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).titleTextAttributes = [NSAttributedString.Key.font: navigationBarFont,  NSAttributedString.Key.foregroundColor: UIColor.black]
        UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).barTintColor = UIColor.white
        UINavigationBar.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).tintColor = UIColor.mnz_redMain()
        UILabel.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).textColor = UIColor.mnz_redMain()
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [QLPreviewController.self]).tintColor = UIColor.mnz_redMain()
        
        //MEGAAssetsPickerController
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGAAssetsPickerController.self]).barStyle = UIBarStyle.black
        UINavigationBar.appearance(whenContainedInInstancesOf: [MEGAAssetsPickerController.self]).barTintColor = UIColor.mnz_redMain()
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [MEGAAssetsPickerController.self]).tintColor = UIColor.white
        
        UISearchBar.appearance().isTranslucent = false
        UISearchBar.appearance().backgroundColor = UIColor.mnz_background()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.mnz_background()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.mnz_label()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        
        let segmentedControlFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.font: segmentedControlFont], for: .normal)
        
        UISwitch.appearance().onTintColor = UIColor.mnz_green00BFA5()
        
        let barButtonItemFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barButtonItemFont], for: .normal)
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = UIColor.mnz_redMain()
        
        UITextField.appearance().tintColor = UIColor.mnz_green00BFA5()
        
        UITextView.appearance().tintColor = UIColor.mnz_green00BFA5()
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.mnz_redMain()
        
        UIProgressView.appearance().tintColor = UIColor.mnz_redMain()
        
        if #available(iOS 10, *) {
            UITabBar.appearance().unselectedItemTintColor = UIColor.mnz_primaryGray(for: traitCollection)
        }
        UITabBar.appearance().tintColor = UIColor .mnz_redMain(for: traitCollection)
        UITabBar.appearance().barTintColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        
        UITableView.appearance().backgroundColor = UIColor.mnz_background()
        UICollectionView.appearance().backgroundColor = UIColor.mnz_background()
        
        UIToolbar.appearance().backgroundColor = UIColor.mnz_mainBarsColor(for: traitCollection)
        UIToolbar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        self.setupThirdPartyAppereance()
    }
    
    class func setupThirdPartyAppereance() {
        let SVProgressHUDFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        SVProgressHUD.setFont(SVProgressHUDFont)
        SVProgressHUD.setRingThickness(2)
        SVProgressHUD.setRingNoTextRadius(18)
        SVProgressHUD.setBackgroundColor(UIColor.mnz_grayF7F7F7())
        SVProgressHUD.setForegroundColor(UIColor.mnz_gray666666())
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.custom)
        SVProgressHUD.setHapticsEnabled(true)
        
        SVProgressHUD.setSuccessImage(UIImage(named: "hudSuccess")!)
        SVProgressHUD.setSuccessImage(UIImage(named: "hudError")!)
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
}
