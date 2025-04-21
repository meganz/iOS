@testable import MEGA
import MEGADomain
import MEGATest
import Testing
import XCTest

@Suite("OverDiskQuotaViewModelTests")
@MainActor
struct OverDiskQuotaViewModelTests {
    // MARK: - Helper
    private static func makeSUT(
        notificationCenter: NotificationCenter = NotificationCenter(),
        router: MockOverDiskQuotaViewRouter? = nil
    ) -> OverDiskQuotaViewModel {
        OverDiskQuotaViewModel(router: router, notificationCenter: notificationCenter)
    }
    
    // MARK: - Tests
    @Suite("OverDiskQuota button actions")
    @MainActor
    struct OverDiskQuotaButtons {
        @Test("Call showUpgradePlanPage when Upgrade button is tapped")
        func upgradeButton() {
            let router = MockOverDiskQuotaViewRouter()
            let sut = makeSUT(router: router)
            
            sut.dispatch(.didTapUpgradeButton)
            
            #expect(router.showUpgradePlanPage_calledTimes == 1)
        }
        
        @Test("Call dismiss when Dismiss button is tapped")
        func dismiss() {
            let router = MockOverDiskQuotaViewRouter()
            let sut = makeSUT(router: router)
            
            sut.dispatch(.didTapDismissButton)
            
            #expect(router.dismiss_calledTimes == 1)
        }
    }
}

final class OverDiskQuotaViewModelNotificationTests: XCTestCase {
    @MainActor
    func testAccountDidPurchasedPlanNotification_whenReceived_shouldDismissView() {
        let expectation = XCTestExpectation(description: "Router dismiss called")
        let notification = NotificationCenter()
        let router = MockOverDiskQuotaViewRouter(
            dismissAction: {
                expectation.fulfill()
            }
        )
        let sut = OverDiskQuotaViewModel(router: router, notificationCenter: notification)

        sut.dispatch(.onViewDidLoad)
        notification.post(name: .accountDidPurchasedPlan, object: nil)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(router.dismiss_calledTimes, 1, "Expected router.dismiss() to be called once after notification")
    }
}
