@testable import Accounts
import AccountsMock
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATest
import XCTest

final class OnboardingUpgradeAccountViewModelTests: XCTestCase {
    private let freePlan = PlanEntity(type: .free, name: "Free")
    private let proI_monthly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .monthly)
    private let proI_yearly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly)
    private let proII_monthly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .monthly)
    private let proII_yearly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .yearly)
    private let proIII_monthly = PlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .monthly)

    @MainActor
    func testLowestProPlan_shouldHaveCorrectProPlan() async {
        let expectedLowestPlan = PlanEntity(type: .proI,
                                                   subscriptionCycle: .monthly,
                                                   price: 1)
        let planList = [PlanEntity(type: .proII, subscriptionCycle: .monthly, price: 2),
                        expectedLowestPlan,
                        PlanEntity(type: .proIII, subscriptionCycle: .monthly, price: 3)]
        
        let (sut, _) = makeSUT(planList: planList)
        
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.lowestProPlan, expectedLowestPlan)
    }
    
    @MainActor
    func testStorageContentMessage_shouldHaveCorrectMessage() async {
        let expectedPlanStorage = "2"
        let expectedPlanStorageUnit = "TB"
        let expectedStorageMessage = Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.message
            .replacingOccurrences(of: "[A]", with: expectedPlanStorage)
            .replacingOccurrences(of: "[B]", with: expectedPlanStorageUnit)
        let expectedLowestPlan = PlanEntity(type: .proI,
                                                   name: "Pro I",
                                                   subscriptionCycle: .monthly, 
                                                   storage: "\(expectedPlanStorage) \(expectedPlanStorageUnit)",
                                                   formattedPrice: "$4.99")
        
        let (sut, _) = makeSUT(planList: [expectedLowestPlan])
        
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.storageContentMessage, expectedStorageMessage)
    }
    
    @MainActor
    func testViewProPlans_onButtonTapped_shouldTrackEvent() {
        let tracker = MockTracker()
        let (sut, _) = makeSUT(tracker: tracker)
        
        sut.showProPlanView()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                OnboardingUpsellingDialogVariantAViewProPlansButtonEvent()
            ]
        )
    }
    
    @MainActor
    func testInit_withEmptyPlanList_shouldSetDefaults() async {
        let (sut, _) = makeSUT()
        await sut.setUpLowestProPlan()
        XCTAssertEqual(sut.lowestProPlan, PlanEntity(), "Expected default empty lowest plan")
        XCTAssertEqual(sut.selectedCycleTab, .yearly, "Expected default cycle tab to be yearly")
    }
    
    @MainActor
    func testSetupPlans_shouldFetchPlansAndSetDefaults() async {
        let planList = [
            PlanEntity(type: .proII, price: 2),
            PlanEntity(type: .proI, price: 1),
            PlanEntity(type: .proIII, price: 3)
        ]
        let (sut, _) = makeSUT(planList: planList)

        await sut.setupPlans()

        XCTAssertEqual(sut.lowestProPlan.type, .proI)
        XCTAssertEqual(sut.lowestProPlan.price, 1)

        XCTAssertTrue(sut.filteredPlanList.contains { $0.type == .free })

        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    @MainActor
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    @MainActor
    func testIsAdsEnabled_withAdsEnabled_shouldBeTrue() {
        let (sut, _) = makeSUT(isAdsEnabled: true)
        
        XCTAssertTrue(sut.isAdsEnabled)
    }
    
    @MainActor
    func testIsAdsEnabled_withAdsDisabled_shouldBefalse() {
        let (sut, _) = makeSUT(isAdsEnabled: false)
        
        XCTAssertFalse(sut.isAdsEnabled)
    }
    
    // MARK: - Plan list
    @MainActor
    private func testFilteredPlanList(planList: [PlanEntity], expectedPlans: [PlanEntity], forCycle cycle: SubscriptionCycleEntity) async {
        let (sut, _) = makeSUT(planList: planList)
        
        await sut.setupPlans()
        sut.selectedCycleTab = cycle
        XCTAssertEqual(sut.filteredPlanList, expectedPlans)
    }

    @MainActor
    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() async {
        await testFilteredPlanList(
            planList: [proI_monthly, proII_monthly, proI_yearly, proII_yearly],
            expectedPlans: [freePlan, proI_monthly, proII_monthly],
            forCycle: .monthly
        )
    }

    @MainActor
    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() async {
        await testFilteredPlanList(
            planList: [proI_monthly, proII_monthly, proI_yearly, proII_yearly],
            expectedPlans: [freePlan, proI_yearly, proII_yearly],
            forCycle: .yearly
        )
    }
    
    // MARK: - Restore
    
    @MainActor
    private func testRestorePurchaseAlert(shouldShowAlertFor status: UpgradeAccountPlanAlertType.AlertStatus) throws {
        let (sut, _) = makeSUT()
        sut.setAlertType(.restore(status))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let resultStatus) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - \(status)")
            return
        }
        XCTAssertEqual(resultStatus, status)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor
    func testRestorePurchaseAlert_successRestore_shouldShowAlertForSuccessRestore() throws {
        try testRestorePurchaseAlert(shouldShowAlertFor: .success)
    }

    @MainActor
    func testRestorePurchaseAlert_incompleteRestore_shouldShowAlertForIncompleteRestore() throws {
        try testRestorePurchaseAlert(shouldShowAlertFor: .incomplete)
    }

    @MainActor
    func testRestorePurchaseAlert_failedRestore_shouldShowAlertForFailedRestore() throws {
        try testRestorePurchaseAlert(shouldShowAlertFor: .failed)
    }

    @MainActor
    func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() {
        let (sut, _) = makeSUT()
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Purchase
    
    @MainActor
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let (sut, mockUseCase) = makeSUT(planList: planList)
        
        await sut.setupPlans()
        sut.setSelectedPlan(proI_monthly)
        
        await sut.purchaseSelectedPlan()
        
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }
    
    @MainActor
    func testPurchasePlan_selectedFreePlan_shouldDismiss() async {
        let planList = [freePlan, proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let (sut, _) = makeSUT(planList: planList)
        
        await sut.setupPlans()
        sut.setSelectedPlan(freePlan)
        
        await sut.purchaseSelectedPlan()
        
        XCTAssertTrue(sut.shouldDismiss)
    }
    
    @MainActor
    func testPurchasePlanAlert_failedPurchase_shouldShowAlertForFailedPurchase() async throws {
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let (sut, _) = makeSUT(planList: planList)
        
        await sut.setupPlans()
        sut.setAlertType(UpgradeAccountPlanAlertType.purchase(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .purchase(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Purchase failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    // MARK: - Event Tracking
    
    @MainActor
    func testTrackProIIICardDisplayedEvent_onMultipleCalls_shouldTrackEventOnce() async {
        let tracker = MockTracker()
        let (sut, _) = makeSUT(tracker: tracker)

        sut.trackProIIICardDisplayedEvent()
        sut.trackProIIICardDisplayedEvent() // Second call to see if it tracks again

        let count = tracker.trackedEventIdentifiers.filter { $0.eventName == OnboardingUpsellingDialogVariantBProPlanIIIDisplayedEvent().eventName }.count
        XCTAssertEqual(count, 1, "Expected Pro III plan card displayed event to be tracked only once")
    }
    
    @MainActor
    private func testPlanSelectionEventTracking(
        planType: AccountTypeEntity,
        expectedEvent: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let tracker = MockTracker()
        let (sut, _) = makeSUT(tracker: tracker)
        sut.setSelectedPlan(PlanEntity(type: planType))

        await sut.purchaseSelectedPlan()

        XCTAssertTrue(
            tracker.trackedEventIdentifiers.contains(
                where: { $0.eventName == expectedEvent }),
            "Expected \(expectedEvent) to be tracked",
            file: file,
            line: line
        )
    }
    
    @MainActor
    func testTrackEvent_forFreePlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .free, expectedEvent: OnboardingUpsellingDialogVariantBFreePlanContinueButtonPressedEvent().eventName)
    }

    @MainActor
    func testTrackEvent_forProIPlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .proI, expectedEvent: OnboardingUpsellingDialogVariantBProIPlanContinueButtonPressedEvent().eventName)
    }

    @MainActor
    func testTrackEvent_forProIIPlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .proII, expectedEvent: OnboardingUpsellingDialogVariantBProIIPlanContinueButtonPressedEvent().eventName)
    }

    @MainActor
    func testTrackEvent_forProIIIPlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .proIII, expectedEvent: OnboardingUpsellingDialogVariantBProIIIPlanContinueButtonPressedEvent().eventName)
    }

    @MainActor
    func testTrackEvent_forLitePlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .lite, expectedEvent: OnboardingUpsellingDialogVariantBProLitePlanContinueButtonPressedEvent().eventName)
    }

    // MARK: - Helper

    @MainActor
    private func makeSUT(
        planList: [PlanEntity] = [],
        tracker: any AnalyticsTracking = MockTracker(),
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        isAdsEnabled: Bool = false,
        baseStorage: Int = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (OnboardingUpgradeAccountViewModel, MockAccountPlanPurchaseUseCase) {
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let mockAccountUseCase = MockAccountUseCase(accountDetailsResult: accountDetailsResult)
        let router = MockOnboardingUpgradeAccountRouter()
        let sut = OnboardingUpgradeAccountViewModel(
            purchaseUseCase: mockPurchaseUseCase,
            accountUseCase: mockAccountUseCase,
            tracker: tracker, 
            isAdsEnabled: isAdsEnabled,
            baseStorage: baseStorage,
            viewProPlanAction: {},
            router: router
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockPurchaseUseCase)
    }
}
