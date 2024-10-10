@testable import Accounts
import AccountsMock
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class OnboardingUpgradeAccountViewModelTests: XCTestCase {
    private let freePlan = PlanEntity(type: .free, name: "Free")
    private let proI_monthly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .monthly)
    private let proI_yearly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly)
    private let proII_monthly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .monthly)
    private let proII_yearly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .yearly)
    private let proIII_monthly = PlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .monthly)

    func testLowestProPlan_shouldHaveCorrectProPlan() async {
        let expectedLowestPlan = PlanEntity(type: .proI,
                                                   subscriptionCycle: .monthly,
                                                   price: 1)
        let planList = [PlanEntity(type: .proII, subscriptionCycle: .monthly, price: 2),
                        expectedLowestPlan,
                        PlanEntity(type: .proIII, subscriptionCycle: .monthly, price: 3)]
        
        let (sut, _) = makeSUT(planList: planList)
        await awaitRegisterDelegateTask(in: sut)
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.lowestProPlan, expectedLowestPlan)
    }
    
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
        await awaitRegisterDelegateTask(in: sut)
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.storageContentMessage, expectedStorageMessage)
    }
    
    func testViewProPlans_onButtonTapped_shouldTrackEvent() async {
        let tracker = MockTracker()
        let (sut, _) = makeSUT(tracker: tracker)
        
        await awaitRegisterDelegateTask(in: sut)
        
        sut.showProPlanView()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                OnboardingUpsellingDialogVariantAViewProPlansButtonEvent()
            ]
        )
    }
    
    func testInit_withEmptyPlanList_shouldSetDefaults() async {
        let (sut, _) = makeSUT()
        await awaitRegisterDelegateTask(in: sut)
        await sut.setUpLowestProPlan()
        XCTAssertEqual(sut.lowestProPlan, PlanEntity(), "Expected default empty lowest plan")
        XCTAssertEqual(sut.selectedCycleTab, .yearly, "Expected default cycle tab to be yearly")
    }
    
    func testSetupPlans_shouldFetchPlansAndSetDefaults() async {
        let planList = [
            PlanEntity(type: .proII, price: 2),
            PlanEntity(type: .proI, price: 1),
            PlanEntity(type: .proIII, price: 3)
        ]
        let (sut, _) = makeSUT(planList: planList)
        
        await awaitRegisterDelegateTask(in: sut)

        await sut.setupPlans()

        XCTAssertEqual(sut.lowestProPlan.type, .proI)
        XCTAssertEqual(sut.lowestProPlan.price, 1)

        XCTAssertTrue(sut.filteredPlanList.contains { $0.type == .free })

        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() async {
        let (sut, _) = makeSUT()
        
        await awaitRegisterDelegateTask(in: sut)
        
        await sut.registerDelegateTask?.value
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    func testViewModelInit_registersDelegates() async {
        let (sut, mockPurchaseUseCase) = makeSUT()
        
        await awaitRegisterDelegateTask(in: sut)
        
        await sut.setupPlans()
        
        XCTAssertEqual(mockPurchaseUseCase.registerRestoreDelegateCalled, 1, "registerRestoreDelegate should be called once during initialization")
        XCTAssertEqual(mockPurchaseUseCase.registerPurchaseDelegateCalled, 1, "registerPurchaseDelegate should be called once during initialization")
    }
    
    func testIsAdsEnabled_withAdsEnabled_shouldBeTrue() async {
        let (sut, _) = makeSUT(isAdsEnabled: true)
        await awaitRegisterDelegateTask(in: sut)
        
        XCTAssertTrue(sut.isAdsEnabled)
    }
    
    func testIsAdsEnabled_withAdsDisabled_shouldBefalse() async {
        let (sut, _) = makeSUT(isAdsEnabled: false)
        await awaitRegisterDelegateTask(in: sut)
        
        XCTAssertFalse(sut.isAdsEnabled)
    }
    
    // MARK: - Plan list
    private func testFilteredPlanList(planList: [PlanEntity], expectedPlans: [PlanEntity], forCycle cycle: SubscriptionCycleEntity) async {
        let (sut, _) = makeSUT(planList: planList)
        
        await awaitRegisterDelegateTask(in: sut)
        
        await sut.setupPlans()
        sut.selectedCycleTab = cycle
        XCTAssertEqual(sut.filteredPlanList, expectedPlans)
    }

    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() async {
        await testFilteredPlanList(
            planList: [proI_monthly, proII_monthly, proI_yearly, proII_yearly],
            expectedPlans: [freePlan, proI_monthly, proII_monthly],
            forCycle: .monthly
        )
    }

    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() async {
        await testFilteredPlanList(
            planList: [proI_monthly, proII_monthly, proI_yearly, proII_yearly],
            expectedPlans: [freePlan, proI_yearly, proII_yearly],
            forCycle: .yearly
        )
    }
    
    // MARK: - Restore
    
    private func testRestorePurchaseAlert(shouldShowAlertFor status: UpgradeAccountPlanAlertType.AlertStatus) async throws {
        let (sut, _) = makeSUT()
        sut.setAlertType(.restore(status))
        
        await awaitRegisterDelegateTask(in: sut)
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let resultStatus) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - \(status)")
            return
        }
        XCTAssertEqual(resultStatus, status)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    func testRestorePurchaseAlert_successRestore_shouldShowAlertForSuccessRestore() async throws {
        try await testRestorePurchaseAlert(shouldShowAlertFor: .success)
    }

    func testRestorePurchaseAlert_incompleteRestore_shouldShowAlertForIncompleteRestore() async throws {
        try await testRestorePurchaseAlert(shouldShowAlertFor: .incomplete)
    }

    func testRestorePurchaseAlert_failedRestore_shouldShowAlertForFailedRestore() async throws {
        try await testRestorePurchaseAlert(shouldShowAlertFor: .failed)
    }

    func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() async {
        let (sut, _) = makeSUT()
        sut.setAlertType(nil)
        
        await awaitRegisterDelegateTask(in: sut)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Purchase
    
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let (sut, mockUseCase) = makeSUT(planList: planList)
        await awaitRegisterDelegateTask(in: sut)
        
        await sut.setupPlans()
        sut.setSelectedPlan(proI_monthly)
        
        sut.purchaseSelectedPlan()
        await sut.purchasePlanTask?.value
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }
    
    func testPurchasePlan_selectedFreePlan_shouldDismiss() async {
        let planList = [freePlan, proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let (sut, _) = makeSUT(planList: planList)
        await awaitRegisterDelegateTask(in: sut)
        
        await sut.setupPlans()
        sut.setSelectedPlan(freePlan)
        
        sut.purchaseSelectedPlan()
        await sut.purchasePlanTask?.value
        XCTAssertTrue(sut.shouldDismiss)
    }
    
    func testPurchasePlanAlert_failedPurchase_shouldShowAlertForFailedPurchase() async throws {
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let (sut, _) = makeSUT(planList: planList)
        await awaitRegisterDelegateTask(in: sut)
        
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
    
    func testTrackProIIICardDisplayedEvent_onMultipleCalls_shouldTrackEventOnce() async {
        let tracker = MockTracker()
        let (sut, _) = makeSUT(tracker: tracker)
        
        await awaitRegisterDelegateTask(in: sut)

        sut.trackProIIICardDisplayedEvent()
        sut.trackProIIICardDisplayedEvent() // Second call to see if it tracks again

        let count = tracker.trackedEventIdentifiers.filter { $0.eventName == OnboardingUpsellingDialogVariantBProPlanIIIDisplayedEvent().eventName }.count
        XCTAssertEqual(count, 1, "Expected Pro III plan card displayed event to be tracked only once")
    }
    
    private func testPlanSelectionEventTracking(
        planType: AccountTypeEntity,
        expectedEvent: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let tracker = MockTracker()
        let (sut, _) = makeSUT(tracker: tracker)
        sut.setSelectedPlan(PlanEntity(type: planType))
        
        await sut.registerDelegateTask?.value

        sut.purchaseSelectedPlan()

        XCTAssertTrue(
            tracker.trackedEventIdentifiers.contains(
                where: { $0.eventName == expectedEvent }),
            "Expected \(expectedEvent) to be tracked",
            file: file,
            line: line
        )
    }
    
    func testTrackEvent_forFreePlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .free, expectedEvent: OnboardingUpsellingDialogVariantBFreePlanContinueButtonPressedEvent().eventName)
    }

    func testTrackEvent_forProIPlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .proI, expectedEvent: OnboardingUpsellingDialogVariantBProIPlanContinueButtonPressedEvent().eventName)
    }

    func testTrackEvent_forProIIPlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .proII, expectedEvent: OnboardingUpsellingDialogVariantBProIIPlanContinueButtonPressedEvent().eventName)
    }

    func testTrackEvent_forProIIIPlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .proIII, expectedEvent: OnboardingUpsellingDialogVariantBProIIIPlanContinueButtonPressedEvent().eventName)
    }

    func testTrackEvent_forLitePlan_shouldTrackCorrectEvent() async {
        await testPlanSelectionEventTracking(planType: .lite, expectedEvent: OnboardingUpsellingDialogVariantBProLitePlanContinueButtonPressedEvent().eventName)
    }

    // MARK: - Helper

    private func makeSUT(
        planList: [PlanEntity] = [],
        tracker: AnalyticsTracking = MockTracker(),
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        isAdsEnabled: Bool = false,
        baseStorage: Int = 20,
        file: StaticString = #file,
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
    
    private func awaitRegisterDelegateTask(in viewModel: OnboardingUpgradeAccountViewModel) async {
        XCTAssertNotNil(viewModel.registerDelegateTask, "Expected registerDelegateTask to be initialized.")
        await viewModel.registerDelegateTask?.value
    }
}
