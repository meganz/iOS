@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class BannerContainerViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewWillAppear() {
        let sut = makeSUT(withOfflineLogOutWarningDismissed: true)
        test(viewModel: sut.viewModel, action: .onViewWillAppear, expectedCommands: [.hideBanner(animated: false)])
    }
    
    @MainActor func testAction_OnViewDidLoad_WarningDismissed() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.preference[.offlineLogOutWarningDismissed] == Optional<Bool>.none)
        test(viewModel: sut.viewModel, action: .onClose, expectedCommands: [.hideBanner(animated: true)])
        
        XCTAssertTrue(sut.preference[.offlineLogOutWarningDismissed] == true)
        test(viewModel: sut.viewModel, action: .onViewDidLoad(UITraitCollection()), expectedCommands: [])
    }
    
    @MainActor func testAction_OnViewDidLoad_WarningNotDismissed() {
        let sut = makeSUT()
        
        XCTAssertTrue(sut.preference[.offlineLogOutWarningDismissed] == Optional<Bool>.none)
        test(viewModel: sut.viewModel,
             action: .onViewDidLoad(UITraitCollection()),
             expectedCommands: [.configureView(message: "Banner message example",
                                               backgroundColor: BannerType.warning.bgColor,
                                               textColor: BannerType.warning.textColor,
                                               actionIcon: BannerType.warning.actionIcon)])
    }
    
    @MainActor func testAction_OnTrailCollectionDidChange() {
        test(viewModel: makeSUT().viewModel,
             action: .onTraitCollectionDidChange(UITraitCollection()),
             expectedCommands: [
                .configureView(message: "Banner message example",
                               backgroundColor: BannerType.warning.bgColor,
                               textColor: BannerType.warning.textColor,
                               actionIcon: BannerType.warning.actionIcon)])
    }
    
    @MainActor func testAction_onClose() {
        test(viewModel: makeSUT().viewModel, action: .onClose, expectedCommands: [.hideBanner(animated: true)])
    }
    
    // MARK: - Private methods
    
    private func makeSUT(
        withOfflineLogOutWarningDismissed offlineLogOutWarningDismissed: Bool? = nil
    ) -> (viewModel: BannerContainerViewModel, preference: some PreferenceUseCaseProtocol) {
        let preferenceUseCase = MockPreferenceUseCase()
        if let offlineLogOutWarningDismissed {
            preferenceUseCase.dict[.offlineLogOutWarningDismissed] = offlineLogOutWarningDismissed
        }
        
        return (BannerContainerViewModel(
            message: "Banner message example",
            type: .warning,
            preferenceUseCase: preferenceUseCase
        ), preferenceUseCase)
    }
}
