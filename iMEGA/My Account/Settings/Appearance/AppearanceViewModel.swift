import Foundation
import MEGADomain
import MEGAPresentation

class AppearanceViewModel {
    
    enum SaveSettingValue {
        case showHiddenItems(Bool)
        case autoMediaDiscoverySetting(Bool)
        case mediaDiscoveryShouldIncludeSubfolderSetting(Bool)
        case hideRecentActivity(Bool)
    }
    
    @PreferenceWrapper(key: .shouldDisplayMediaDiscoveryWhenMediaOnly, defaultValue: true)
    var autoMediaDiscoverySetting: Bool
    @PreferenceWrapper(key: .mediaDiscoveryShouldIncludeSubfolderMedia, defaultValue: true)
    var mediaDiscoveryShouldIncludeSubfolderSetting: Bool
    
    let mediaDiscoveryHelpLink = URL(string: "https://help.mega.io/files-folders/view-move/media-discovery-view-gallery")
    
    private let accountUseCase: any AccountUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(preferenceUseCase: some PreferenceUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.accountUseCase = accountUseCase
        self.featureFlagProvider = featureFlagProvider
        
        $autoMediaDiscoverySetting.useCase = preferenceUseCase
        $mediaDiscoveryShouldIncludeSubfolderSetting.useCase = preferenceUseCase
    }
    
    func isAppearanceSectionVisible(section: AppearanceSection?) -> Bool {
        switch section {
        case .hiddenItems:
            guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else {
                return false
            }
            return [.free, .none]
                .notContains(accountUseCase.currentAccountDetails?.proLevel)
        case .none:
            return false
        case .launch, .layout, .recents, .appIcon, .mediaDiscovery, .mediaDiscoverySubfolder:
            return true
        }
    }
    
    func saveSetting(for setting: SaveSettingValue) {
        switch setting {
        case .showHiddenItems(let value):
            print("ShowHiddenItems: \(value)") // userAttributeUseCase.retrieveScheduledMeetingOnBoardingAttrubute()
        case .autoMediaDiscoverySetting(let value):
            autoMediaDiscoverySetting = value
        case .mediaDiscoveryShouldIncludeSubfolderSetting(let value):
            mediaDiscoveryShouldIncludeSubfolderSetting = value
        case .hideRecentActivity(let value):
            RecentsPreferenceManager.setShowRecents(!value)
        }
    }
}
