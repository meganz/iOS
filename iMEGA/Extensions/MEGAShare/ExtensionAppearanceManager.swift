import Foundation

class ExtensionAppearanceManager: NSObject {
    
    @objc class func setupAppearance(_ traitCollection: UITraitCollection) {
        setupNavigationBarAppearance(traitCollection)
        
        // To tint the color of the prompt.
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).textColor = UIColor.label
        
        UISearchBar.appearance().isTranslucent = false
        UISearchBar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.systemBackground
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.label
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        UITextField.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UIProgressView.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UITableView.appearance().backgroundColor = UIColor.systemBackground
        UIButton.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        UITableViewCell.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UICollectionView.appearance().backgroundColor = UIColor.systemBackground
        UIButton.appearance(whenContainedInInstancesOf: [UICollectionViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        
        UIToolbar.appearance().barTintColor = UIColor.mnz_mainBars(for: traitCollection)
        UIToolbar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        self.configureSVProgressHUD(traitCollection)
        
        self.setupToolbar(traitCollection)
    }
    
    class func configureSVProgressHUD(_ traitCollection: UITraitCollection) {
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.custom)
        SVProgressHUD.setMinimumSize(CGSize(width: 180, height: 100))
        SVProgressHUD.setRingThickness(2)
        SVProgressHUD.setRingRadius(16)
        SVProgressHUD.setRingNoTextRadius(16)
        SVProgressHUD.setCornerRadius(8)
        
        SVProgressHUD.setShadowOffset(CGSize(width: 0, height: 1))
        SVProgressHUD.setShadowOpacity(0.15)
        SVProgressHUD.setShadowRadius(8)
        SVProgressHUD.setShadowColor(MEGAAppColor.Black._000000.uiColor)
        SVProgressHUD.setHudViewCustomBlurEffect(UIBlurEffect.init(style: UIBlurEffect.Style.systemChromeMaterial))
        SVProgressHUD.setFont(UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold))
        SVProgressHUD.setForegroundColor(UIColor.mnz_primaryGray(for: traitCollection))
        SVProgressHUD.setForegroundImageColor(UIColor.mnz_primaryGray(for: traitCollection))
        SVProgressHUD.setBackgroundColor(UIColor.systemBackground)
        SVProgressHUD.setHapticsEnabled(true)
        
        SVProgressHUD.setSuccessImage(UIImage.hudSuccess)
        SVProgressHUD.setErrorImage(UIImage.hudError)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
    }
    
    @objc class func forceNavigationBarUpdate(_ navigationBar: UINavigationBar, traitCollection: UITraitCollection) {
        navigationBar.standardAppearance.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        navigationBar.scrollEdgeAppearance?.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        navigationBar.standardAppearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)]
        navigationBar.standardAppearance.doneButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)]
        
        navigationBar.tintColor = UIColor.mnz_primaryGray(for: traitCollection)
    }
    
    @objc class func forceSearchBarUpdate(_ searchBar: UISearchBar, traitCollection: UITraitCollection) {
        searchBar.tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        searchBar.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
    }
    
    @objc class func forceToolbarUpdate(_ toolbar: UIToolbar, traitCollection: UITraitCollection) {
        toolbar.standardAppearance.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        toolbar.standardAppearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)]
        
        toolbar.barTintColor = UIColor.mnz_mainBars(for: traitCollection)
        
        let numberOfBarButtonItems: Int = toolbar.items?.count ?? 0
        for i in 0..<numberOfBarButtonItems {
            let barButtonItem = toolbar.items?[i]
            barButtonItem?.tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        }
    }
    
    // MARK: - Private
    
    private class func setupNavigationBarAppearance(_ traitCollection: UITraitCollection) {
        UINavigationBar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UINavigationBar.appearance().isTranslucent = false

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        
        navigationBarAppearance.shadowImage = nil
        navigationBarAppearance.shadowColor = nil
        
        let backArrowImage = UIImage.backArrow
        navigationBarAppearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    }
    
    private class func setupToolbar(_ traitCollection: UITraitCollection) {
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.configureWithDefaultBackground()
        toolbarAppearance.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15 {
            UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
        }
    }
}
