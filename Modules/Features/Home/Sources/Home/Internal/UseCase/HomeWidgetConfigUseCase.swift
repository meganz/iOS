import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGAPreference

protocol HomeWidgetConfigUseCaseProtocol: Sendable {
    func widgetConfigs() -> [HomeWidgetConfigEntity]
    func enabledWidgetTypes() -> [HomeWidgetType]
    func save(_ configs: [HomeWidgetConfigEntity])
}

struct HomeWidgetConfigUseCase: HomeWidgetConfigUseCaseProtocol {
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

    func widgetConfigs() -> [HomeWidgetConfigEntity] {
        guard let storedData,
              let stored = try? JSONDecoder().decode([HomeWidgetConfigEntity].self, from: storedData) else {
            return HomeWidgetConfigEntity.defaultConfigs
        }
        return reconciledWithDefaults(stored)
    }

    func enabledWidgetTypes() -> [HomeWidgetType] {
        widgetConfigs()
            .filter(\.isEnabled)
            .map(\.type)
    }

    func save(_ configs: [HomeWidgetConfigEntity]) {
        guard let data = try? JSONEncoder().encode(configs) else { return }
        storedData = data
    }

    // In case we add more widgets to HomeWidgetType in the future, we'll need to include the newly added widgets
    private func reconciledWithDefaults(_ stored: [HomeWidgetConfigEntity]) -> [HomeWidgetConfigEntity] {
        let storedTypes = Set(stored.map(\.type))
        let missing = HomeWidgetType.allCases
            .filter { !storedTypes.contains($0) }
            .map { HomeWidgetConfigEntity(type: $0, isEnabled: true) }
        return stored + missing
    }
}
