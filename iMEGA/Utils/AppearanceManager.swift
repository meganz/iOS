import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken

@MainActor
class AppearanceManager: NSObject {

    @objc class func setupAppearance(_ traitCollection: UITraitCollection) {
        setupNavigationBarAppearance()
        
        UISearchBar.appearance().isTranslucent = false
        UISearchBar.appearance().tintColor = TokenColors.Text.secondary
        UISearchBar.appearance().backgroundColor = TokenColors.Background.surface1
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = TokenColors.Background.surface2
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.label
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        
        UISwitch.appearance().onTintColor = TokenColors.Support.success
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.label
        
        UITextField.appearance().tintColor = TokenColors.Icon.accent
        
        UIProgressView.appearance().backgroundColor = UIColor.clear
        UIProgressView.appearance().tintColor = TokenColors.Support.success
        
        UITableView.appearance().backgroundColor = TokenColors.Background.page
        UITableView.appearance().separatorColor = TokenColors.Border.strong
        UIButton.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        UITableViewCell.appearance().tintColor = TokenColors.Support.success
        
        UICollectionView.appearance().backgroundColor = TokenColors.Background.page
        UIButton.appearance(whenContainedInInstancesOf: [UICollectionViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        
        self.setupActivityIndicatorAppearance()
        
        self.setupToolbar()
        
        self.configureSVProgressHUD()
    }
    
    @objc class func configureSVProgressHUD() {
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
        SVProgressHUD.setForegroundColor(TokenColors.Text.secondary)
        SVProgressHUD.setForegroundImageColor(TokenColors.Text.secondary)
        SVProgressHUD.setBackgroundColor(TokenColors.Background.page)
        SVProgressHUD.setHapticsEnabled(true)
        
        SVProgressHUD.setSuccessImage(MEGAAssets.UIImage.hudSuccess)
        SVProgressHUD.setErrorImage(MEGAAssets.UIImage.hudError)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
    }
    
    @objc class func forceNavigationBarUpdate(_ navigationBar: UINavigationBar) {
        navigationBar.tintColor = UIColor.barTint()
        
        let navigationBarAppearance = makeNavigationBarAppearance()
        
        navigationBar.standardAppearance = navigationBarAppearance
        navigationBar.scrollEdgeAppearance = navigationBarAppearance
    }
    
    @objc class func forceNavigationBarTitleUpdate(_ navigationBar: UINavigationBar) {
        navigationBar.standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.primaryTextColor()]
        navigationBar.scrollEdgeAppearance?.titleTextAttributes = [.foregroundColor: UIColor.primaryTextColor()]
    }
    
    @objc class func forceSearchBarUpdate(_ searchBar: UISearchBar,
                                          backgroundColorWhenDesignTokenEnable: UIColor) {
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
    
    @objc class func forceToolbarUpdate(_ toolbar: UIToolbar) {
        let appearance = makeUIToolbarAppearance()
        toolbar.standardAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        let numberOfBarButtonItems: Int = toolbar.items?.count ?? 0
        for i in 0..<numberOfBarButtonItems {
            let barButtonItem = toolbar.items?[i]
            barButtonItem?.tintColor = TokenColors.Icon.primary
        }
    }
    
    @objc class func setupTabbar(_ tabBar: UITabBar) {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) {
            setupTabbarForRevampedAppearance(tabBar)
        } else {
            setupTabbarForLegacyAppearance(tabBar)
        }
    }

    private class func setupTabbarForRevampedAppearance(_ tabBar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .surface1Background()

        let normalColor = TokenColors.Text.secondary
        let selectedColor = TokenColors.Button.brand

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.stackedLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: TokenColors.Components.interactive]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]

        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = .init(horizontal: 0, vertical: -3)
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: TokenColors.Button.brand]
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = .init(horizontal: 0, vertical: -3)

        appearance.inlineLayoutAppearance.normal.iconColor = normalColor
        appearance.inlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.inlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: TokenColors.Components.interactive]

        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        appearance.compactInlineLayoutAppearance.normal.iconColor = normalColor
        appearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.compactInlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: TokenColors.Components.interactive]
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        tabBar.items?.forEach {
            $0.imageInsets = .init(top: -3, left: 0, bottom: 3, right: 0)
        }
    }

    private class func setupTabbarForLegacyAppearance(_ tabBar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .surface1Background()

        appearance.stackedLayoutAppearance.normal.iconColor = TokenColors.Text.secondary
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.stackedLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: TokenColors.Components.interactive]
        appearance.stackedLayoutAppearance.selected.iconColor = TokenColors.Button.brand

        appearance.inlineLayoutAppearance.normal.iconColor = TokenColors.Text.secondary
        appearance.inlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.inlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: TokenColors.Components.interactive]
        appearance.inlineLayoutAppearance.selected.iconColor = TokenColors.Button.brand

        appearance.compactInlineLayoutAppearance.normal.iconColor = TokenColors.Text.secondary
        appearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.compactInlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: TokenColors.Components.interactive]
        appearance.compactInlineLayoutAppearance.selected.iconColor = TokenColors.Button.brand

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        tabBar.items?.forEach {
            if tabBar.traitCollection.horizontalSizeClass == .regular {
                $0.imageInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
            } else {
                $0.imageInsets = .init(top: 6, left: 0, bottom: -6, right: 0)
            }
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
    class func forceResetNavigationBar() {
        AppearanceManager.setupNavigationBarAppearance()
    }
    
    // MARK: - Private
    
    private class func setupNavigationBarAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.barTint()
        UINavigationBar.appearance().isTranslucent = false
        
        let navigationBarAppearance = makeNavigationBarAppearance()
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    }
    
    private class func makeNavigationBarAppearance() -> UINavigationBarAppearance {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .surface1Background()
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.primaryTextColor()]
        
        navigationBarAppearance.shadowImage = nil
        navigationBarAppearance.shadowColor = nil
        
        let backArrowImage = MEGAAssets.UIImage.backArrow
        navigationBarAppearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
        
        let barButtonItemAppearance = UIBarButtonItemAppearance()
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: TokenColors.Text.primary]
        barButtonItemAppearance.disabled.titleTextAttributes = [.foregroundColor: TokenColors.Text.disabled]
        
        navigationBarAppearance.buttonAppearance = barButtonItemAppearance
        
        navigationBarAppearance.doneButtonAppearance.normal.titleTextAttributes = [.foregroundColor: TokenColors.Text.primary]
        
        return navigationBarAppearance
    }
    
    private class func setupActivityIndicatorAppearance() {
        UIActivityIndicatorView.appearance().style = .medium
    }
    
    private class func setupToolbar() {
        let toolbarAppearance = makeUIToolbarAppearance()
        
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
        UIToolbar.appearance().tintColor = TokenColors.Icon.primary
    }
    
    private class func makeUIToolbarAppearance() -> UIToolbarAppearance {
        let toolbarAppearance = UIToolbarAppearance()
        
        toolbarAppearance.configureWithDefaultBackground()
        toolbarAppearance.backgroundColor = .surface1Background()
        
        toolbarAppearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: TokenColors.Text.primary]
        toolbarAppearance.buttonAppearance.disabled.titleTextAttributes = [.foregroundColor: TokenColors.Text.disabled]
        
        toolbarAppearance.shadowImage = nil
        toolbarAppearance.shadowColor = TokenColors.Border.strong
        
        return toolbarAppearance
    }
}
