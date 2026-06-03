import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAPreference

protocol HomeWidgetCustomizationUseCaseProtocol: Sendable {
    func customizableConfigs() -> [HomeWidgetConfigEntity]
    func save(_ configs: [HomeWidgetConfigEntity])
    func reset()
}

struct HomeWidgetCustomizationUseCase: HomeWidgetCustomizationUseCaseProtocol {
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

    func customizableConfigs() -> [HomeWidgetConfigEntity] {
        allStoredConfigs()
            .syncedWithNewWidgets()
            .filter { $0.type != .promotionalBanners }
    }

    func save(_ configs: [HomeWidgetConfigEntity]) {
        guard let data = try? JSONEncoder().encode(configs) else { return }
        storedData = data
    }

    func reset() {
        $storedData.remove()
    }

    private func allStoredConfigs() -> [HomeWidgetConfigEntity] {
        guard let storedData,
              let stored = HomeWidgetConfigEntity.safelyDecodedWidgetConfigs(from: storedData) else {
            return HomeWidgetConfigEntity.defaultConfigs
        }
        return stored
    }
}
