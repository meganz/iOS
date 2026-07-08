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

@MainActor
@objc final class TabManager: NSObject {

    private override init() {}

    @PreferenceWrapper(key: PreferenceKeyEntity.launchTab, defaultValue: Tab.TabType.home.rawValue, useCase: PreferenceUseCase.default)
    private static var launchTabPreference: Tab.TabType.RawValue

    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSelected, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabSelected: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.launchTabSuggested, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabDialogAlreadySuggested: Bool

    // MARK: - Default launch destination in Home revamp
    //
    // In the past TabManager's launchTabPreference is the source of truth for storing the default launch tab,
    // After Home Revamp, the source of truth is launchDestinationUseCase which can handle non-tab-based destination.
    private static let launchDestinationUseCase: any DefaultLaunchDestinationUseCaseProtocol =
    DefaultLaunchDestinationUseCase(
        preferenceUseCase: PreferenceUseCase.default,
        repository: DefaultLaunchDestinationRepository.newRepo
    )

    private static var isHomeRevampPhaseTwoEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .iosHomeRevampPhaseTwo)
    }

    private(set) static var designatedTab: Tab?

    @objc static func setDesignatedTab(tab: Tab?) {
        designatedTab = tab
    }

    static func setPreferenceTab(_ tab: Tab) {
        guard isHomeRevampPhaseTwoEnabled else {
            launchTabPreference = tab.tabType.rawValue
            launchTabSelected = true
            return
        }
        launchDestinationUseCase.setDestination(destination(for: tab))
    }

    static func getPreferenceTab() -> Tab {
        guard isHomeRevampPhaseTwoEnabled else {
            return appTabs.first(where: { $0.tabType.rawValue == launchTabPreference }) ?? .home
        }
        return tab(for: launchDestinationUseCase.selectedDestination)
    }

    // We need to migrate existing/legacy source of truth for launch destination
    // from TabManager to launchDestinationUseCase
    @objc static func migrateLegacyLaunchTabIfNeeded() {
        guard isHomeRevampPhaseTwoEnabled,
              !launchDestinationUseCase.hasSelectedDestination,
              launchTabSelected else { return }
        let legacyTab = appTabs.first(where: { $0.tabType.rawValue == launchTabPreference }) ?? .home
        launchDestinationUseCase.setDestination(destination(for: legacyTab))
    }

    private static func tab(for destination: LaunchDestinationEntity) -> Tab {
        switch destination {
        case .home: return .home
        case .drive: return .cloudDrive
        case .media: return .cameraUploads
        case .chat: return .chat
        case .sharedItems, .favourites, .offline:
            // Non-tab destinations default to .home; AppDelegate routes them after launch.
            return .home
        }
    }

    private static func destination(for tab: Tab) -> LaunchDestinationEntity {
        return switch tab.tabType {
        case .cloudDrive: .drive
        case .cameraUploads: .media
        case .home: .home
        case .chat: .chat
        case .menu: .home
        }
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
    static let appTabs: [Tab] = [.home, .cloudDrive, .cameraUploads, .chat, .menu]
}

@MainActor
@objc final class Tab: NSObject {
    fileprivate enum TabType: String {
        case cloudDrive
        case cameraUploads
        case home
        case chat
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

    @objc static func menuTabIndex() -> Int {
        indexOfTab(.menu)
    }
}

extension Tab.TabType {
    fileprivate var icon: UIImage {
        return switch self {
        case .cloudDrive: MEGAAssets.UIImage.tabBarDrive
        case .cameraUploads: MEGAAssets.UIImage.tabBarPhotos
        case .home: MEGAAssets.UIImage.tabBarHome
        case .chat: MEGAAssets.UIImage.tabBarChat
        case .menu: MEGAAssets.UIImage.tabBarMenu
        }
    }

    fileprivate var selectedIcon: UIImage {
        return switch self {
        case .cloudDrive: MEGAAssets.UIImage.tabBarDriveSelected
        case .cameraUploads: MEGAAssets.UIImage.tabBarPhotosSelected
        case .home: MEGAAssets.UIImage.tabBarHomeSelected
        case .chat: MEGAAssets.UIImage.tabBarChatSelected
        case .menu: MEGAAssets.UIImage.tabBarMenuSelected
        }
    }

    fileprivate var title: String {
        return switch self {
        case .cloudDrive: Strings.Localizable.TabbarTitle.drive
        case .cameraUploads: Strings.Localizable.Photos.SearchResults.Media.Section.title
        case .home: Strings.Localizable.TabbarTitle.home
        case .chat: Strings.Localizable.TabbarTitle.chat
        case .menu: Strings.Localizable.TabbarTitle.menu
        }
    }
}
