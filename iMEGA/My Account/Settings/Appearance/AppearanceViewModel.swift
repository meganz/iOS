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
    
    enum SettingValue {
        case showHiddenItems
        case autoMediaDiscoverySetting
        case mediaDiscoveryShouldIncludeSubfolderSetting
        case hideRecentActivity
    }
    
    let mediaDiscoveryHelpLink = URL(string: "https://help.mega.io/files-folders/view-move/media-discovery-view-gallery")
    
    @PreferenceWrapper(key: .shouldDisplayMediaDiscoveryWhenMediaOnly, defaultValue: true)
    private var autoMediaDiscoverySetting: Bool
    @PreferenceWrapper(key: .mediaDiscoveryShouldIncludeSubfolderMedia, defaultValue: true)
    private var mediaDiscoveryShouldIncludeSubfolderSetting: Bool
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    
    init(preferenceUseCase: some PreferenceUseCaseProtocol,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) {
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        
        $autoMediaDiscoverySetting.useCase = preferenceUseCase
        $mediaDiscoveryShouldIncludeSubfolderSetting.useCase = preferenceUseCase
    }
    
    @MainActor
    func fetchSettingValue(for setting: SettingValue) async -> Bool {
        switch setting {
        case .showHiddenItems:
            return await contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        case .autoMediaDiscoverySetting:
            return autoMediaDiscoverySetting
        case .mediaDiscoveryShouldIncludeSubfolderSetting:
            return mediaDiscoveryShouldIncludeSubfolderSetting
        case .hideRecentActivity:
            return !RecentsPreferenceManager.showRecents()
        }
    }
    
    func isAppearanceSectionVisible(section: AppearanceSection?) -> Bool {
        switch section {
        case .hiddenItems:
            guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) else {
                return false
            }
            return sensitiveNodeUseCase.isAccessible()
        case .none:
            return false
        case .launch, .layout, .recents, .appIcon, .mediaDiscovery, .mediaDiscoverySubfolder:
            return true
        }
    }
    
    func saveSetting(for setting: SaveSettingValue) {
        switch setting {
        case .showHiddenItems(let value):
            Task { await saveShowHiddenNodesSetting(showHiddenNodes: value) }
        case .autoMediaDiscoverySetting(let value):
            autoMediaDiscoverySetting = value
        case .mediaDiscoveryShouldIncludeSubfolderSetting(let value):
            mediaDiscoveryShouldIncludeSubfolderSetting = value
        case .hideRecentActivity(let value):
            RecentsPreferenceManager.setShowRecents(!value)
        }
    }
    
    private func saveShowHiddenNodesSetting(showHiddenNodes: Bool) async {
        do {
            try await contentConsumptionUserAttributeUseCase.saveSensitiveSetting(showHiddenNodes: showHiddenNodes)
        } catch {
            MEGALogError("Error occurred when updating showHiddenNodes attribute. \(error.localizedDescription)")
        }
    }
}
