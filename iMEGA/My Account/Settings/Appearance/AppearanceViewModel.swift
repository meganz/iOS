import Foundation
import MEGADomain
import MEGAPresentation

class AppearanceViewModel {
    
    @PreferenceWrapper(key: .shouldDisplayMediaDiscoveryWhenMediaOnly, defaultValue: true)
    var autoMediaDiscoverySetting: Bool
    @PreferenceWrapper(key: .mediaDiscoveryShouldIncludeSubfolderMedia, defaultValue: true)
    var mediaDiscoveryShouldIncludeSubfolderSetting: Bool
    
    let mediaDiscoveryHelpLink = URL(string: "https://help.mega.io/files-folders/view-move/media-discovery-view-gallery")
    
    init(preferenceUseCase: some PreferenceUseCaseProtocol) {
        $autoMediaDiscoverySetting.useCase = preferenceUseCase
        $mediaDiscoveryShouldIncludeSubfolderSetting.useCase = preferenceUseCase
    }
}
