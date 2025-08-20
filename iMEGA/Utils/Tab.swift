import Foundation
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

    /// Migrate the `launchTabPreference` from using `Int` to `Tab.TabType.RawValue`
    static func migrateDefaultTabPreferenceIfNeeded() {
        let legacyLaunchTabPreference: PreferenceWrapper<Int?, PreferenceKeyEntity> = PreferenceWrapper(
            key: PreferenceKeyEntity.launchTab,
            defaultValue: nil,
            useCase: PreferenceUseCase.default 
        )

        if let legacyLaunchTabIndex = legacyLaunchTabPreference.wrappedValue,
           let legacyLaunchTab = legacyAppTabs[safe: legacyLaunchTabIndex] {
            launchTabPreference = legacyLaunchTab.tabType.rawValue
        }
    }

    private override init() {}
    private static let isNavigationRevampEnabled = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)

    @PreferenceWrapper(key: PreferenceKeyEntity.launchTab, defaultValue: Tab.TabType.home.rawValue, useCase: PreferenceUseCase.default)
    private static var launchTabPreference: Tab.TabType.RawValue

    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSelected, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabSelected: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSuggested, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabDialogAlreadySuggested: Bool

    private(set) static var designatedTab: Tab?

    @objc static func setDesignatedTab(tab: Tab?) {
        designatedTab = tab
    }

    static func setPreferenceTab(_ tab: Tab) {
        launchTabPreference = tab.tabType.rawValue
        launchTabSelected = true
    }

    static func getPreferenceTab() -> Tab {
        appTabs.first(where: { $0.tabType.rawValue == launchTabPreference }) ?? .home
    }
    
    static func isLaunchTabSelected() -> Bool {
        launchTabSelected
    }
    
    static func isLaunchTabDialogAlreadySuggested() -> Bool {
        launchTabDialogAlreadySuggested
    }
    
    static func setLaunchTabDialogAlreadyAsSuggested() {
        launchTabDialogAlreadySuggested = true
    }

    // List of tabs in the app's tab bar
    private static let legacyAppTabs: [Tab] = [.cloudDrive, .cameraUploads, .home, .chat, .sharedItems]
    private static let revampedAppTabs: [Tab] = [.home, .cloudDrive, .cameraUploads, .chat, .menu]

    static var appTabs: [Tab] = {
        isNavigationRevampEnabled ? revampedAppTabs : legacyAppTabs
    }()
}

@objc final class Tab: NSObject {
    fileprivate enum TabType: String {
        case cloudDrive
        case cameraUploads
        case home
        case chat
        case sharedItems
        case menu
    }

    let icon: UIImage
    let selectedIcon: UIImage?
    let title: String
    fileprivate let tabType: TabType

    static let cloudDrive = Tab(tabType: .cloudDrive)
    static let cameraUploads = Tab(tabType: .cameraUploads)
    static let home = Tab(tabType: .home)
    static let chat = Tab(tabType: .chat)
    static let sharedItems = Tab(tabType: .sharedItems)
    static let menu = Tab(tabType: .menu)

    fileprivate init(tabType: TabType) {
        self.icon = tabType.icon
        self.selectedIcon = tabType.selectedIcon
        self.title = tabType.title
        self.tabType = tabType
        super.init()
    }
}

extension TabManager {
    static var selectedTab: Tab {
        Self.designatedTab ?? Self.getPreferenceTab()
    }

    static func tabAtIndex(_ index: Int) -> Tab? {
        appTabs[safe: index]
    }

    static func indexOfTab(_ tab: Tab) -> Int {
        guard let index = appTabs.firstIndex(of: tab) else {
            assertionFailure("TabManager should always have a \(tab.title) tab")
            return 0
        }
        return index
    }

    @objc static func homeTabIndex() -> Int {
        indexOfTab(.home)
    }

    @objc static func driveTabIndex() -> Int {
        indexOfTab(.cloudDrive)
    }

    @objc static func photosTabIndex() -> Int {
        indexOfTab(.cameraUploads)
    }

    @objc static func chatTabIndex() -> Int {
        indexOfTab(.chat)
    }

    @objc static func sharedItemsTabIndex() -> Int {
        indexOfTab(.sharedItems)
    }

    @objc static func menuTabIndex() -> Int {
        indexOfTab(.menu)
    }
}

extension Tab.TabType {
    fileprivate var icon: UIImage {
        let isNavigationRevampEnabled = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)
        return switch self {
        case.cloudDrive: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarDrive : MEGAAssets.UIImage.cloudDriveIcon
        case .cameraUploads: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarPhotos : MEGAAssets.UIImage.cameraUploadsIcon
        case .home: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarHome : MEGAAssets.UIImage.home
        case .chat: isNavigationRevampEnabled ? MEGAAssets.UIImage.tabBarChat : MEGAAssets.UIImage.chatIcon
        case .sharedItems: MEGAAssets.UIImage.sharedItemsIcon
        case .menu: MEGAAssets.UIImage.tabBarMenu
        }
    }

    fileprivate var selectedIcon: UIImage? {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) else {
            return nil
        }
        return switch self {
        case .cloudDrive: MEGAAssets.UIImage.tabBarDriveSelected
        case .cameraUploads: MEGAAssets.UIImage.tabBarPhotosSelected
        case .home: MEGAAssets.UIImage.tabBarHomeSelected
        case .chat: MEGAAssets.UIImage.tabBarChatSelected
        case .sharedItems: nil
        case .menu: MEGAAssets.UIImage.tabBarMenuSelected
        }
    }

    fileprivate var title: String {
        let isNavigationRevampEnabled = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp)
        return switch self {
        case.cloudDrive: isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.drive : Strings.Localizable.cloudDrive
        case .cameraUploads: Strings.Localizable.TabbarTitle.photos
        case .home: isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.home : Strings.Localizable.home
        case .chat: isNavigationRevampEnabled ? Strings.Localizable.TabbarTitle.chat : Strings.Localizable.chat
        case .sharedItems: Strings.Localizable.sharedItems
        case .menu: Strings.Localizable.TabbarTitle.menu
        }
    }
}
