@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class CallWillEndAlertViewModelTests: XCTestCase {
    func testAction_onViewReady() {
        let router = MockCallWillEndAlertRouter()
        let viewModel = CallWillEndAlertViewModel(
            router: router,
            accountUseCase: MockAccountUseCase(),
            timeToEndCall: 10,
            dismissCompletion: nil
        )
        
        viewModel.viewReady()
        
        XCTAssert(router.showCallWillEndAlert_CalledTimes == 1)
        XCTAssert(router.updateCallWillEndAlertTitle_CalledTimes == 1)
    }
}

final class MockCallWillEndAlertRouter: CallWillEndAlertRouting {
    var showCallWillEndAlert_CalledTimes = 0
    var updateCallWillEndAlertTitle_CalledTimes = 0
    var showUpgradeAccount_CalledTimes = 0
    var dismissCallWillEndAlertIfNeeded_CalledTimes = 0

    func showCallWillEndAlert(upgradeAction: @escaping () -> Void, notNowAction: @escaping () -> Void) {
        showCallWillEndAlert_CalledTimes += 1
    }
    
    func updateCallWillEndAlertTitle(remainingMinutes: Int) {
        updateCallWillEndAlertTitle_CalledTimes += 1
    }
    
    func showUpgradeAccount(_ account: MEGADomain.AccountDetailsEntity) {
        showUpgradeAccount_CalledTimes += 1
    }
    
    func dismissCallWillEndAlertIfNeeded() {
        dismissCallWillEndAlertIfNeeded_CalledTimes += 1
    }
}
