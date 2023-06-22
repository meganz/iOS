@testable import MEGA
import MEGADomainMock
import XCTest

final class BannerContainerViewModelTests: XCTestCase {
    
    let router = MockBannerContainerViewRouter()
    
    lazy var viewModel = BannerContainerViewModel(router: router, message: "Banner message example", type: BannerType.warning)
    
    func testAction_onViewWillAppear() {
        test(viewModel: viewModel, action: .onViewWillAppear, expectedCommands: [.hideBanner(animated: false)])
    }
    
    func testAction_OnViewDidLoad_WarningDismissed() {
        let preference = MockPreferenceUseCase()
        XCTAssertTrue(preference[.offlineLogOutWarningDismissed] == Optional<Bool>.none)
        
        let viewModel = BannerContainerViewModel(router: router, message: "Banner message example", type: BannerType.warning, preferenceUseCase: preference)
        
        test(viewModel: viewModel, action: .onClose, expectedCommands: [.hideBanner(animated: true)])
        
        XCTAssertTrue(preference[.offlineLogOutWarningDismissed] == true)
        
        test(viewModel: viewModel,
             action: .onViewDidLoad(UITraitCollection()),
             expectedCommands: [])
    }
    
    func testAction_OnViewDidLoad_WarningNotDismissed() {
        let preference = MockPreferenceUseCase()
        XCTAssertTrue(preference[.offlineLogOutWarningDismissed] == Optional<Bool>.none)
        
        let viewModel = BannerContainerViewModel(router: router, message: "Banner message example", type: BannerType.warning, preferenceUseCase: preference)

        test(viewModel: viewModel,
             action: .onViewDidLoad(UITraitCollection()),
             expectedCommands: [.configureView(message: "Banner message example",
                                               backgroundColor: BannerType.warning.bgColor,
                                               textColor: BannerType.warning.textColor,
                                               actionIcon: BannerType.warning.actionIcon)])
    }
    
    func testAction_OnTrailCollectionDidChange() {
        test(viewModel: viewModel,
             action: .onTraitCollectionDidChange(UITraitCollection()),
             expectedCommands: [
                .configureView(message: "Banner message example",
                               backgroundColor: BannerType.warning.bgColor,
                               textColor: BannerType.warning.textColor,
                               actionIcon: BannerType.warning.actionIcon)])
    }
    
    func testAction_onClose() {
        test(viewModel: viewModel, action: .onClose, expectedCommands: [.hideBanner(animated: true)])
    }
}
