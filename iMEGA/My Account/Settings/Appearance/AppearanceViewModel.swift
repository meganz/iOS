import Foundation
import MEGADomain
import MEGAPresentation

class AppearanceViewModel {
    
    @PreferenceWrapper(key: .shouldDisplayMediaDiscoveryWhenMediaOnly, defaultValue: true)
    var autoMediaDiscoverySetting: Bool
    @PreferenceWrapper(key: .mediaDiscoveryShouldIncludeSubfolderMedia, defaultValue: true)
    var mediaDiscoveryShouldIncludeSubfolderSetting: Bool
    
    let showMediaDiscoverySetting: Bool
    
    var mediaDiscoveryHelpLink: URL? {
        guard showMediaDiscoverySetting else {
            return nil
        }
        return URL(string: "https://help.mega.io/files-folders/view-move/media-discovery-view-gallery")
    }
    
    init(preferenceUseCase: some PreferenceUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol) {
        showMediaDiscoverySetting = featureFlagProvider
            .isFeatureFlagEnabled(for: .cloudDriveMediaDiscoveryIntegration)
        $autoMediaDiscoverySetting.useCase = preferenceUseCase
        $mediaDiscoveryShouldIncludeSubfolderSetting.useCase = preferenceUseCase
    }
}
