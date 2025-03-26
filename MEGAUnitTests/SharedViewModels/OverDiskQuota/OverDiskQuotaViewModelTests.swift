@testable import MEGA
import MEGADomain
import MEGATest
import Testing

@Suite("OverDiskQuotaViewModelTests")
@MainActor
struct OverDiskQuotaViewModelTests {
    // MARK: - Helper
    private static func makeSUT(
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> (OverDiskQuotaViewModel, MockOverDiskQuotaViewRouter) {
        let router = MockOverDiskQuotaViewRouter()
        return (OverDiskQuotaViewModel(router: router, notificationCenter: notificationCenter), router)
    }
    
    // MARK: - Tests
    @Suite("OverDiskQuota subscribed notification")
    @MainActor
    struct OverDiskQuotaSubscribedNotification {
        @Test("Dismiss ODQ view when accountDidPurchasedPlan is received")
        func accountDidPurchasedPlanNotification() async throws {
            let notification = NotificationCenter()
            let (sut, router) = makeSUT(notificationCenter: notification)

            sut.dispatch(.onViewDidLoad)
            notification.post(name: .accountDidPurchasedPlan, object: nil)
            
            try await Task.sleep(nanoseconds: 1_500_000_000)
            #expect(router.dismiss_calledTimes == 1)
        }
    }
    
    @Suite("OverDiskQuota button actions")
    @MainActor
    struct OverDiskQuotaButtons {
        @Test("Call showUpgradePlanPage when Upgrade button is tapped")
        func upgradeButton() {
            let (sut, router) = makeSUT()
            
            sut.dispatch(.didTapUpgradeButton)
            
            #expect(router.showUpgradePlanPage_calledTimes == 1)
        }
        
        @Test("Call dismiss when Dismiss button is tapped")
        func dismiss() {
            let (sut, router) = makeSUT()
            
            sut.dispatch(.didTapDismissButton)
            
            #expect(router.dismiss_calledTimes == 1)
        }
    }
}
