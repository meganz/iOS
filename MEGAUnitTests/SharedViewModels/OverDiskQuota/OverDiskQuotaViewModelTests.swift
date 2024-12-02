@testable import MEGA
import MEGADomain
import MEGATest
import Testing

@Suite("OverDiskQuotaViewModelTests")
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
    struct OverDiskQuotaSubscribedNotification {
        @Test("Dismiss ODQ view when accountDidPurchasedPlan is received")
        func accountDidPurchasedPlanNotification() async throws {
            let notification = NotificationCenter()
            let (sut, router) = makeSUT(notificationCenter: notification)

            await sut.dispatch(.onViewDidLoad)
            notification.post(name: .accountDidPurchasedPlan, object: nil)
            
            try await Task.sleep(nanoseconds: 1_500_000_000)
            await #expect(router.dismiss_calledTimes == 1)
        }
    }
    
    @Suite("OverDiskQuota button actions")
    struct OverDiskQuotaButtons {
        @Test("Call showUpgradePlanPage when Upgrade button is tapped")
        func upgradeButton() {
            let (sut, router) = makeSUT()
            
            sut.dispatch(.didTapUpgradeButton)
            
            #expect(router.showUpgradePlanPage_calledTimes == 1)
        }
        
        @Test("Call navigateToCloudDriveTab when Make some space button is tapped")
        func makeSomeSpaceButton() {
            let (sut, router) = makeSUT()
            
            sut.dispatch(.didTapMakeSomeSpaceButton)
            
            #expect(router.navigateToCloudDriveTab_calledTimes == 1)
        }
    }
}
