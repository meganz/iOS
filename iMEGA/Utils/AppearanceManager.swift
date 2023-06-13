
import Foundation
import MEGASwift

class AppearanceManager: NSObject {
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
    
    @objc class func setupAppearance(_ traitCollection: UITraitCollection) {
        guard UIApplication.shared.applicationState == .active else {
            shared.pendingTraitCollection = traitCollection
            return
        }
        setupNavigationBarAppearance(traitCollection)
        
        UISearchBar.appearance().isTranslucent = false
        UISearchBar.appearance().tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        UISearchBar.appearance().backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.mnz_background()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.mnz_label()
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        
        let segmentedControlFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedString.Key.font: segmentedControlFont], for: .normal)
        
        UISwitch.appearance().onTintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.mnz_label()
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        
        UITextField.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UITextView.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UIProgressView.appearance().backgroundColor = UIColor.clear
        UIProgressView.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UITableView.appearance().backgroundColor = UIColor.mnz_background()
        UITableView.appearance().separatorColor = UIColor.mnz_separator(for: traitCollection)
        UIButton.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).tintColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        UITableViewCell.appearance().tintColor = UIColor.mnz_turquoise(for: traitCollection)
        
        UICollectionView.appearance().backgroundColor = UIColor.mnz_background()
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
        SVProgressHUD.setShadowColor(UIColor.black)
        SVProgressHUD.setHudViewCustomBlurEffect(UIBlurEffect.init(style: UIBlurEffect.Style.systemChromeMaterial))
        SVProgressHUD.setFont(UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.semibold))
        SVProgressHUD.setForegroundColor(UIColor.mnz_primaryGray(for: traitCollection))
        SVProgressHUD.setForegroundImageColor(UIColor.mnz_primaryGray(for: traitCollection))
        SVProgressHUD.setBackgroundColor(UIColor.mnz_secondaryBackground(for: traitCollection))
        SVProgressHUD.setHapticsEnabled(true)
        
        SVProgressHUD.setSuccessImage(Asset.Images.Hud.hudSuccess.image)
        SVProgressHUD.setErrorImage(Asset.Images.Hud.hudError.image)
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
        toolbar.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        
        let numberOfBarButtonItems: Int = toolbar.items?.count ?? 0
        for i in 0..<numberOfBarButtonItems {
            let barButtonItem = toolbar.items?[i]
            barButtonItem?.tintColor = UIColor.mnz_primaryGray(for: traitCollection)
        }
    }
    
    @objc class func setupTabbar(_ tabBar: UITabBar, traitCollection: UITraitCollection) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.mnz_primaryGray(for: traitCollection)
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.stackedLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.mnz_red(for: traitCollection)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.mnz_red(for: traitCollection)
        
        appearance.inlineLayoutAppearance.normal.iconColor = UIColor.mnz_primaryGray(for: traitCollection)
        appearance.inlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.inlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.mnz_red(for: traitCollection)]
        appearance.inlineLayoutAppearance.selected.iconColor = UIColor.mnz_red(for: traitCollection)
        
        appearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.mnz_primaryGray(for: traitCollection)
        appearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor = .clear
        appearance.compactInlineLayoutAppearance.normal.badgeTextAttributes = [.foregroundColor: UIColor.mnz_red(for: traitCollection)]
        appearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.mnz_red(for: traitCollection)
        
        tabBar.standardAppearance = appearance

        if #available(iOS 15.0, *), ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15 {
            tabBar.scrollEdgeAppearance = appearance
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
        
        let backArrowImage = Asset.Images.Chat.backArrow.image
        navigationBarAppearance.setBackIndicatorImage(backArrowImage, transitionMaskImage: backArrowImage)
        
        let barButtonItemAppearance = UIBarButtonItemAppearance()
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.mnz_primaryGray(for: traitCollection)]
        navigationBarAppearance.buttonAppearance = barButtonItemAppearance
        navigationBarAppearance.doneButtonAppearance = barButtonItemAppearance
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    }
    
    private class func setupActivityIndicatorAppearance(_ traitCollection: UITraitCollection) {
        UIActivityIndicatorView.appearance().style = .medium
        UIActivityIndicatorView.appearance().color = (traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark) ? UIColor.white : UIColor.mnz_primaryGray(for: traitCollection)
    }
    
    private class func setupToolbar(_ traitCollection: UITraitCollection) {
        let toolbarAppearance = UIToolbarAppearance.init()
        toolbarAppearance.configureWithDefaultBackground()
        toolbarAppearance.backgroundColor = UIColor.mnz_mainBars(for: traitCollection)
        UIToolbar.appearance().standardAppearance = toolbarAppearance
        if #available(iOS 15.0, *) {
            UIToolbar.appearance().scrollEdgeAppearance = toolbarAppearance
        }
    }
    
    @objc private func appDidBecomeActive() {
        guard let pendingTraitChange = pendingTraitCollection else { return }
        AppearanceManager.setupAppearance(pendingTraitChange)
    }
}
