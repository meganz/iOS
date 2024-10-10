import MEGADesignToken
import MEGAPresentation

class AppearanceManager: NSObject {
    
#if MAIN_APP_TARGET
    private static let shared = AppearanceManager()
    private var pendingTraitCollection: UITraitCollection?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        guard let pendingTraitCollection else { return }
        AppearanceManager.setupAppearance(pendingTraitCollection)
    }
#endif
    
    @objc class func setupAppearance(_ traitCollection: UITraitCollection) {
#if MAIN_APP_TARGET
        guard UIApplication.shared.applicationState == .active else {
            shared.pendingTraitCollection = traitCollection
            return
        }
#endif
        setupNavigationBarAppearance(traitCollection)
        
        UISearchBar.appearance().isTranslucent = false
        UISearchBar.appearance().tintColor = UIColor.mnz_primaryGray()
        UISearchBar.appearance().backgroundColor = .surface1Background()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.systemBackground
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.label
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        
        UISwitch.appearance().onTintColor = TokenColors.Support.success
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.label
        
        UITextField.appearance().tintColor = TokenColors.Icon.accent
        
        UIProgressView.appearance().backgroundColor = UIColor.clear
        UIProgressView.appearance().tintColor = TokenColors.Support.success
        
        UITableView.appearance().backgroundColor = TokenColors.Background.page
        UITableView.appearance().separatorColor = UIColor.mnz_separator()
        UIButton.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        UITableViewCell.appearance().tintColor = TokenColors.Support.success
        
        UICollectionView.appearance().backgroundColor = TokenColors.Background.page
        UIButton.appearance(whenContainedInInstancesOf: [UICollectionViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        
        self.setupActivityIndicatorAppearance(traitCollection)
        
        self.setupToolbar(traitCollection)
        
        self.configureSVProgressHUD(traitCollection)
    }
    
    @objc class func configureSVProgressHUD(_ traitCollection: UITraitCollection) {
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.custom)
        SVProgressHUD.setMinimumSize(CGSize(width: 180, height: 100))
        SVProgressHUD.setRingThickness(2)
        SVProgressHUD.setRingRadius(16)
        SVProgressHUD.setRingNoTextRadius(16)
        SVProgressHUD.setCornerRadius(8)
        SVProgressHUD.setShadowOffset(CGSize(width: 0, height: 1))
        SVProgressHUD.setShadowOpacity(0.15)
        SVProgressHUD.setShadowRadius(8)
        SVProgressHUD.setShadowColor(TokenColors.Text.primary)
        SVProgressHUD.setHudViewCustomBlurEffect(UIBlurEffect.init(style: UIBlurEffect.Style.systemChromeMaterial))
        SVProgressHUD.setFont(UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold))
        SVProgressHUD.setForegroundColor(UIColor.mnz_primaryGray())
        SVProgressHUD.setForegroundImageColor(UIColor.mnz_primaryGray())
        SVProgressHUD.setBackgroundColor(UIColor.mnz_secondaryBackground(for: traitCollection))
        SVProgressHUD.setHapticsEnabled(true)
        
        SVProgressHUD.setSuccessImage(UIImage.hudSuccess)
        SVProgressHUD.setErrorImage(UIImage.hudError)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
    }
    
    @objc class func forceNavigationBarUpdate(_ navigationBar: UINavigationBar, traitCollection: UITraitCollection) {
        navigationBar.tintColor = UIColor.barTint()
        
        let navigationBarAppearance = makeNavigationBarAppearance(traitCollection)
        
        navigationBar.standardAppearance = navigationBarAppearance
        navigationBar.scrollEdgeAppearance = navigationBarAppearance
    }
    
    @objc class func forceNavigationBarTitleUpdate(_ navigationBar: UINavigationBar, traitCollection: UITraitCollection) {
        navigationBar.standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.primaryTextColor()]
        navigationBar.scrollEdgeAppearance?.titleTextAttributes = [.foregroundColor: UIColor.primaryTextColor()]
    }
    
    @objc class func forceSearchBarUpdate(_ searchBar: UISearchBar,
                                          backgroundColorWhenDesignTokenEnable: UIColor,
                                          traitCollection: UITraitCollection) {
        // In order to set the color for `searchBar.searchTextField.backgroundColor`, we need to set `searchBar.searchTextField.borderStyle = .none` otherwise the correct will display incorrectly
        // and since `searchBar.searchTextField.borderStyle = .none` removes the default rounded corner, we need to re-set it.
        searchBar.searchTextField.borderStyle = .none
        searchBar.searchTextField.layer.cornerRadius = 10
        searchBar.tintColor = TokenColors.Text.placeholder
        searchBar.backgroundColor = backgroundColorWhenDesignTokenEnable
        searchBar.searchTextField.backgroundColor = TokenColors.Background.surface2
        searchBar.searchTextField.leftView?.tintColor = TokenColors.Text.placeholder
        searchBar.searchTextField.textColor = TokenColors.Text.primary
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: searchBar.placeholder ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: TokenColors.Text.placeholder]
        )
    }
    
    @objc class func forceToolbarUpdate(_ toolbar: UIToolbar, traitCollection: UITraitCollection) {
        let appearance = makeUIToolbarAppearance(traitCollection)
        toolbar.standardAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        let numberOfBarButtonItems: Int = toolbar.items?.count ?? 0
        for i in 0..<numberOfBarButtonItems {
            let barButtonItem = toolbar.items?[i]
            barButtonItem?.tintColor = TokenColors.Icon.primary
        }
    }
    
    @objc class func setupTabbar(_ tabBar: UITabBar, traitCollection: UITraitCollection) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .surface1Background()
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.mnz_primaryGray()
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.stackedLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.mnz_badgeRed()]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.mnz_red()
        
        appearance.inlineLayoutAppearance.normal.iconColor = UIColor.mnz_primaryGray()
        appearance.inlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.inlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.mnz_badgeRed()]
        appearance.inlineLayoutAppearance.selected.iconColor = UIColor.mnz_red()
        
        appearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.mnz_primaryGray()
        appearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.compactInlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.mnz_badgeRed()]
        appearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.mnz_red()
        
        tabBar.standardAppearance = appearance
        
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15 {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    /// This method and `forceResetNavigationBar` were introduced
    /// to fix the issue of navigation bar's transparency
    /// in `CNContactPickerViewController`
    class func setTranslucentNavigationBar() {
        UINavigationBar.appearance().isTranslucent = true
    }
    
    /// This is the associated method with `setTranslucentNavigationBar`
    /// which is used to reset the global navigation bar to the state
    /// before the global navigation bar is changed.
    /// - Parameter traitCollection: The `trailCollection` in which the navigation bar appearance is changed.
    class func forceResetNavigationBar(_ traitCollection: UITraitCollection) {
        AppearanceManager.setupNavigationBarAppearance(traitCollection)
    }
    
    // MARK: - Private
    
    private class func setupNavigationBarAppearance(_ traitCollection: UITraitCollection) {
        UINavigationBar.appearance().tintColor = UIColor.barTint()
        UINavigationBar.appearance().isTranslucent = false
        
        let navigationBarAppearance = makeNavigationBarAppearance(traitCollection)
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    }
    
    private class func makeNavigationBarAppearance(_ traitCollection: UITraitCollection) -> UINavigationBarAppearance {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .surface1Background()
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.primaryTextColor()]
        
        navigationBarAppearance.shadowImage = nil
        navigationBarAppearance.shadowColor = nil
        
        let backArrowImage = UIImage.backArrow
        navigationBarAppearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
        
        let barButtonItemAppearance = UIBarButtonItemAppearance()
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.barButtonTitleColor(isEnabled: true)]
        barButtonItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.barButtonTitleColor(isEnabled: false)]
        
        navigationBarAppearance.buttonAppearance = barButtonItemAppearance
        
        navigationBarAppearance.doneButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.barButtonTitleColor(isEnabled: true)]
        
        return navigationBarAppearance
    }
    
    private class func setupActivityIndicatorAppearance(_ traitCollection: UITraitCollection) {
        UIActivityIndicatorView.appearance().style = .medium
        UIActivityIndicatorView.appearance().color = (traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? UIColor.whiteFFFFFF : UIColor.mnz_primaryGray()
    }
    
    private class func setupToolbar(_ traitCollection: UITraitCollection) {
        let toolbarAppearance = makeUIToolbarAppearance(traitCollection)
        
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
        UIToolbar.appearance().tintColor = TokenColors.Icon.primary
    }
    
    private class func makeUIToolbarAppearance(_ traitCollection: UITraitCollection) -> UIToolbarAppearance {
        let toolbarAppearance = UIToolbarAppearance()
        
        toolbarAppearance.configureWithDefaultBackground()
        toolbarAppearance.backgroundColor = .surface1Background()
        
        toolbarAppearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.barButtonTitleColor(isEnabled: true)]
        toolbarAppearance.buttonAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.barButtonTitleColor(isEnabled: false)]
        
        toolbarAppearance.shadowImage = nil
        toolbarAppearance.shadowColor = UIColor.mnz_toolbarShadow(for: traitCollection)
        
        return toolbarAppearance
    }
}
