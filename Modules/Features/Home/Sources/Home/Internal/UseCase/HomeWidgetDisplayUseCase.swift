import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAPreference

protocol HomeWidgetDisplayUseCaseProtocol: Sendable {
    func allVisibleWidgetTypes() -> [HomeWidgetType]
}

package struct HomeWidgetDisplayUseCase: HomeWidgetDisplayUseCaseProtocol {
    @PreferenceWrapper(key: PreferenceKeyEntity.homeWidgetConfigs, defaultValue: nil)
    private var storedData: Data?

    init() {
        self.init(
            preferenceUseCase: PreferenceUseCase(repository: PreferenceRepository.newRepo)
        )
    }

    package init(preferenceUseCase: some PreferenceUseCaseProtocol) {
        $storedData.useCase = preferenceUseCase
    }

    package func allVisibleWidgetTypes() -> [HomeWidgetType] {
        var types = enabledWidgetTypes()
        // Banners are always visible and placed after .accountDetails or .shortcuts, if none are present, banners are located at the top
        let anchorIndex = types.firstIndex(of: .accountDetails)
            ?? types.firstIndex(of: .shortcuts)
        types.insert(.promotionalBanners, at: anchorIndex.map { $0 + 1 } ?? 0)
        return types
    }

    private func enabledWidgetTypes() -> [HomeWidgetType] {
        storedConfigs()
            .filter { $0.type != .promotionalBanners && $0.isEnabled }
            .map(\.type)
    }

    private func storedConfigs() -> [HomeWidgetConfigEntity] {
        guard let storedData,
              let stored = HomeWidgetConfigEntity.safelyDecodedWidgetConfigs(from: storedData) else {
            return HomeWidgetConfigEntity.defaultConfigs
        }
        return stored.syncedWithNewWidgets()
    }
}
