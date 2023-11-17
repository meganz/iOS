@testable import Accounts
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class OnboardingUpgradeAccountViewModelTests: XCTestCase {

    func testLowestProPlan_shouldHaveCorrectProPlan() async {
        let expectedLowestPlan = AccountPlanEntity(type: .proI,
                                                   subscriptionCycle: .monthly,
                                                   price: 1)
        let planList = [AccountPlanEntity(type: .proII, subscriptionCycle: .monthly, price: 2),
                        expectedLowestPlan,
                        AccountPlanEntity(type: .proIII, subscriptionCycle: .monthly, price: 3)]
        
        let sut = makeSUT(planList: planList)
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.lowestProPlan, expectedLowestPlan)
    }
    
    func testStorageContentMessage_shouldHaveCorrectMessage() async {
        let expectedPlanStorage = "2"
        let expectedPlanStorageUnit = "TB"
        let expectedStorageMessage = Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.message
            .replacingOccurrences(of: "[A]", with: expectedPlanStorage)
            .replacingOccurrences(of: "[B]", with: expectedPlanStorageUnit)
        let expectedLowestPlan = AccountPlanEntity(type: .proI,
                                                   name: "Pro I",
                                                   subscriptionCycle: .monthly, 
                                                   storage: "\(expectedPlanStorage) \(expectedPlanStorageUnit)",
                                                   formattedPrice: "$4.99")
        
        let sut = makeSUT(planList: [expectedLowestPlan])
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.storageContentMessage, expectedStorageMessage)
    }
    
    func testViewProPlans_onButtonTapped_shouldTrackEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(planList: [], tracker: tracker)
        
        sut.showProPlanView()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                OnboardingUpsellingDialogVariantAViewProPlansButtonEvent()
            ]
        )
    }
    
    // MARK: Helper

    private func makeSUT(
        planList: [AccountPlanEntity],
        tracker: AnalyticsTracking = MockTracker(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> OnboardingUpgradeAccountViewModel {
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = OnboardingUpgradeAccountViewModel(
            purchaseUseCase: mockPurchaseUseCase,
            tracker: tracker,
            viewProPlanAction: {}
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
