import MEGADomain

@objc enum TabType: Int, CaseIterable {
    case cloudDrive
    case cameraUploads
    case home
    case chat
    case sharedItems
}

@objc final class TabManager: NSObject {
    @PreferenceWrapper(key: .launchTab, defaultValue: TabType.home.rawValue, useCase: PreferenceUseCase.default)
    private static var launchTabPreference: Int
    @PreferenceWrapper(key: .launchTabSelected, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabSelected: Bool
    @PreferenceWrapper(key: .launchTabSuggested, defaultValue: false, useCase: PreferenceUseCase.default)
    private static var launchTabDialogAlreadySuggested: Bool

    @objc static let avaliableTabs = TabType.allCases.count
    
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
}

@objc final class Tab: NSObject {
    @objc let tabType: TabType
    
    @objc init(tabType: TabType) {
        self.tabType = tabType
    }
    
    @objc var icon: UIImage? {
        switch tabType {
        case .cloudDrive:
            return Asset.Images.TabBarIcons.cloudDriveIcon.image
            
        case .cameraUploads:
            return Asset.Images.TabBarIcons.cameraUploadsIcon.image
            
        case .home:
            return Asset.Images.TabBarIcons.home.image
            
        case .chat:
            return Asset.Images.TabBarIcons.chatIcon.image
            
        case .sharedItems:
            return Asset.Images.TabBarIcons.sharedItemsIcon.image
        }
    }
    
    @objc var title: String {
        switch tabType {
        case .cloudDrive:
            return Strings.Localizable.cloudDrive
            
        case .cameraUploads:
            return Strings.Localizable.cameraUploadsLabel
            
        case .home:
            return Strings.Localizable.home
            
        case .chat:
            return Strings.Localizable.chat
            
        case .sharedItems:
            return Strings.Localizable.sharedItems
        }
    }
}
