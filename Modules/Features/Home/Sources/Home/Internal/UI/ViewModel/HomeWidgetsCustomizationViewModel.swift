import Foundation
import MEGAL10n

@MainActor
final class HomeWidgetsCustomizationViewModel: ObservableObject {
    @Published var configs: [HomeWidgetConfigEntity] {
        didSet { widgetCustomizationUseCase.save(configs) }
    }

    private let widgetCustomizationUseCase: any HomeWidgetCustomizationUseCaseProtocol

    package init(widgetCustomizationUseCase: some HomeWidgetCustomizationUseCaseProtocol = HomeWidgetCustomizationUseCase()) {
        self.widgetCustomizationUseCase = widgetCustomizationUseCase
        self.configs = widgetCustomizationUseCase.customizableConfigs()
    }

    func isEnabled(_ widget: HomeWidgetType) -> Bool {
        configs.first { $0.type == widget }?.isEnabled ?? true
    }

    func toggle(_ widget: HomeWidgetType, isOn: Bool) {
        guard let index = configs.firstIndex(where: { $0.type == widget }) else { return }
        configs[index] = HomeWidgetConfigEntity(type: configs[index].type, isEnabled: isOn)
    }

    func move(from source: IndexSet, to destination: Int) {
        configs.move(fromOffsets: source, toOffset: destination)
    }

    func displayTitle(for type: HomeWidgetType) -> String {
        switch type {
        case .shortcuts: Strings.Localizable.shortcuts
        case .recents: Strings.Localizable.recents
        case .accountDetails: Strings.Localizable.Home.Customization.Widget.accountStatus
        case .promotionalBanners: Strings.Localizable.Home.Customization.Widget.banners
        case .viewedLinks: Strings.Localizable.Home.Customization.Widget.viewedLinks
        case .continueWhereYouLeft: Strings.Localizable.Home.Customization.Widget.continueWhereYouLeftOff
        case .doMoreWithMega: Strings.Localizable.Home.Customization.Widget.doMoreWithMega
        }
    }
}
