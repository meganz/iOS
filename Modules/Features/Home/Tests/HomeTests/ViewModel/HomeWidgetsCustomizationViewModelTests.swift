import MEGAL10n
import Testing
@testable import Home

@Suite("HomeWidgetsCustomizationViewModelTests")
@MainActor
struct HomeWidgetsCustomizationViewModelTests {
    @Test("blocks disabling the last enabled widget and shows snack bar")
    func blocksDisablingLastEnabledWidget() {
        let useCase = MockHomeWidgetCustomizationUseCase(configs: [
            HomeWidgetConfigEntity(type: .shortcuts, isEnabled: true),
            HomeWidgetConfigEntity(type: .recents, isEnabled: false)
        ])
        let sut = makeSUT(useCase: useCase)

        sut.toggle(.shortcuts, isOn: false)

        #expect(sut.isEnabled(.shortcuts))
        #expect(sut.snackBar?.message == Strings.Localizable.Home.Customization.DisableLastWidget.Snackbar.message)
        #expect(useCase.savedConfigs.isEmpty)
    }

    @Test("disables a widget while others remain enabled")
    func disablesWidgetWhenOthersRemainEnabled() {
        let useCase = MockHomeWidgetCustomizationUseCase(configs: [
            HomeWidgetConfigEntity(type: .shortcuts, isEnabled: true),
            HomeWidgetConfigEntity(type: .recents, isEnabled: true)
        ])
        let sut = makeSUT(useCase: useCase)

        sut.toggle(.recents, isOn: false)

        #expect(!sut.isEnabled(.recents))
        #expect(sut.snackBar == nil)
        #expect(useCase.savedConfigs.count == 1)
    }

    @Test("enables a disabled widget")
    func enablesDisabledWidget() {
        let useCase = MockHomeWidgetCustomizationUseCase(configs: [
            HomeWidgetConfigEntity(type: .shortcuts, isEnabled: true),
            HomeWidgetConfigEntity(type: .recents, isEnabled: false)
        ])
        let sut = makeSUT(useCase: useCase)

        sut.toggle(.recents, isOn: true)

        #expect(sut.isEnabled(.recents))
        #expect(sut.snackBar == nil)
        #expect(useCase.savedConfigs.count == 1)
    }

    @Test("allows disabling down to one widget, then blocks the last one")
    func allowsDisablingDownToOneWidgetThenBlocksLast() {
        let useCase = MockHomeWidgetCustomizationUseCase(configs: [
            HomeWidgetConfigEntity(type: .shortcuts, isEnabled: true),
            HomeWidgetConfigEntity(type: .recents, isEnabled: true)
        ])
        let sut = makeSUT(useCase: useCase)

        sut.toggle(.shortcuts, isOn: false)

        #expect(!sut.isEnabled(.shortcuts))
        #expect(sut.snackBar == nil)

        sut.toggle(.recents, isOn: false)

        #expect(sut.isEnabled(.recents))
        #expect(sut.snackBar != nil)
        #expect(useCase.savedConfigs.count == 1)
    }

    private func makeSUT(useCase: MockHomeWidgetCustomizationUseCase) -> HomeWidgetsCustomizationViewModel {
        HomeWidgetsCustomizationViewModel(widgetCustomizationUseCase: useCase)
    }
}

private final class MockHomeWidgetCustomizationUseCase: HomeWidgetCustomizationUseCaseProtocol, @unchecked Sendable {
    private(set) var savedConfigs: [[HomeWidgetConfigEntity]] = []
    private(set) var resetCallCount = 0
    private let configs: [HomeWidgetConfigEntity]

    init(configs: [HomeWidgetConfigEntity]) {
        self.configs = configs
    }

    func customizableConfigs() -> [HomeWidgetConfigEntity] { configs }

    func save(_ configs: [HomeWidgetConfigEntity]) {
        savedConfigs.append(configs)
    }

    func reset() {
        resetCallCount += 1
    }
}
