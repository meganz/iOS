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
    case menu
}

@objc final class TabManager: NSObject {
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

    @objc static func setPreferenceTab(tab: Tab) {
        launchTabPreference = tab.tabType.rawValue
        launchTabSelected = true
    }

    @objc static func getPreferenceTab() -> Tab {
        guard let tabType = TabType(rawValue: launchTabPreference) else {
            return Tab(tabType: TabType.home)
        }
        return Tab(tabType: tabType)
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
            return [.init(tabType: .home), .init(tabType: .cloudDrive), .init(tabType: .cameraUploads), .init(tabType: .chat), .init(tabType: .menu)]
        } else {
            return [.init(tabType: .cloudDrive), .init(tabType: .cameraUploads), .init(tabType: .home), .init(tabType: .chat), .init(tabType: .sharedItems)]
        }
    }()
}

@objc final class Tab: NSObject {
    @objc let tabType: TabType
    let icon: UIImage
    let title: String

    // (mike): Use static tabs and take advantage of Equatable for the tabs
    @objc init(tabType: TabType) {
        let isNavigationRevampEnabled = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)
        self.tabType = tabType
        switch tabType {
        case .cloudDrive:
            icon = isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarDrive : MEGAAssets.UIImage.cloudDriveIcon
            title = isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.drive : Strings.Localizable.cloudDrive
        case .cameraUploads:
            icon = isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarPhotos : MEGAAssets.UIImage.cameraUploadsIcon
            title = isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.photos : Strings.Localizable.General.cameraUploads
        case .home:
            icon = isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarHome : MEGAAssets.UIImage.home
            title = isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.home : Strings.Localizable.home
        case .chat:
            icon = isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarChat : MEGAAssets.UIImage.chatIcon
            title = isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.chat : Strings.Localizable.chat
        case .sharedItems: // Shared Items screen is only available in legacy tabbar, no need to check for isNavigationRevampEnabled
            icon = MEGAAssets.UIImage.sharedItemsIcon
            title = Strings.Localizable.sharedItems
        case .menu: // Menu screen is only available in revamped tabbar, no need to check for isNavigationRevampEnabled
            icon = MEGAAssets.UIImage.tabBarMenu
            title = Strings.Localizable.TabbarTitle.menu
        }
    }
}

extension TabManager {
    @objc static var selectedTab: Tab {
        Self.designatedTab ?? Self.getPreferenceTab()
    }
}
