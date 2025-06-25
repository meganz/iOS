import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGAPreference
import MEGASwift

@objc enum TabType: Int, CaseIterable {
    case cloudDrive
    case cameraUploads
    case home
    case chat
    case sharedItems
}

@objc final class TabManager: NSObject {
    // (mike): Try to use Tab instead of Int for storing default tab (IOS-10110)
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTab, defaultValue: TabType.home.rawValue, useCase: PreferenceUseCase.default)
    private static var launchTabPreference: Int
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSelected, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabSelected: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSuggested, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabDialogAlreadySuggested: Bool

    private(set) static var designatedTab: Tab?

    @objc static let avaliableTabs = TabType.allCases.count

    @objc static func setDesignatedTab(tab: Tab?) {
        designatedTab = tab
    }

    static func setPreferenceTab(index: Int) {
        launchTabPreference = index
        launchTabSelected = true
    }

    @objc static func getPreferenceTab() -> Tab {
        appTabs[safe: launchTabPreference] ?? .home
    }
    
    @objc static func isLaunchTabSelected() -> Bool {
        launchTabSelected
    }
    
    @objc static func isLaunchTabDialogAlreadySuggested() -> Bool {
        launchTabDialogAlreadySuggested
    }
    
    @objc static func setLaunchTabDialogAlreadyAsSuggested() {
        launchTabDialogAlreadySuggested = true
    }

    // List of tabs in the app's tab bar
    @objc static var appTabs: [Tab] = {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) {
            return [.home, .cloudDrive, .cameraUploads, .chat, .menu]
        } else {
            return [.cloudDrive, .cameraUploads, .home, .chat, .sharedItems]
        }
    }()
}

@objc final class Tab: NSObject {
    let icon: UIImage
    let title: String

    private static var isNavigationRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)
    }

    static let cloudDrive = Tab(
        icon: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarDrive : MEGAAssets.UIImage.cloudDriveIcon,
        title: isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.drive : Strings.Localizable.cloudDrive
    )

    static let cameraUploads = Tab(
        icon: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarPhotos : MEGAAssets.UIImage.cameraUploadsIcon,
        title: isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.photos : Strings.Localizable.General.cameraUploads
    )

    static let home = Tab(
        icon: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarHome : MEGAAssets.UIImage.home,
        title: isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.home : Strings.Localizable.home
    )

    static let chat = Tab(
        icon: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarChat : MEGAAssets.UIImage.chatIcon,
        title: isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.chat : Strings.Localizable.chat
    )

    static let sharedItems = Tab(
        icon: MEGAAssets.UIImage.sharedItemsIcon,
        title: Strings.Localizable.sharedItems
    )

    static let menu = Tab(
        icon: MEGAAssets.UIImage.tabBarMenu,
        title: Strings.Localizable.TabbarTitle.menu
    )

    fileprivate init(icon: UIImage, title: String) {
        self.icon = icon
        self.title = title
        super.init()
    }
}

extension TabManager {
    @objc static var selectedTab: Tab {
        Self.designatedTab ?? Self.getPreferenceTab()
    }

    static func tabAtIndex(_ index: Int) -> Tab? {
        appTabs[safe: index]
    }

    static func indexOfTab(_ tab: Tab) -> Int? {
        appTabs.firstIndex(of: tab)
    }
}
