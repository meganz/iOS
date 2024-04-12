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
    private let freePlan = AccountPlanEntity(type: .free, name: "Free")
    private let proI_monthly = AccountPlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .monthly)
    private let proI_yearly = AccountPlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly)
    private let proII_monthly = AccountPlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .monthly)
    private let proII_yearly = AccountPlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .yearly)
    private let proIII_monthly = AccountPlanEntity(type: .proIII, name: "Pro III", subscriptionCycle: .monthly)

    func testLowestProPlan_shouldHaveCorrectProPlan() async {
        let expectedLowestPlan = AccountPlanEntity(type: .proI,
                                                   subscriptionCycle: .monthly,
                                                   price: 1)
        let planList = [AccountPlanEntity(type: .proII, subscriptionCycle: .monthly, price: 2),
                        expectedLowestPlan,
                        AccountPlanEntity(type: .proIII, subscriptionCycle: .monthly, price: 3)]
        
        let (sut, _) = makeSUT(planList: planList)
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
        
        let (sut, _) = makeSUT(planList: [expectedLowestPlan])
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.storageContentMessage, expectedStorageMessage)
    }
    
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
    
    func testInit_withEmptyPlanList_shouldSetDefaults() async {
        let (sut, _) = makeSUT()
        await sut.setUpLowestProPlan()
        XCTAssertEqual(sut.lowestProPlan, AccountPlanEntity(), "Expected default empty lowest plan")
        XCTAssertEqual(sut.selectedCycleTab, .yearly, "Expected default cycle tab to be yearly")
    }
    
    func testSetupPlans_shouldFetchPlansAndSetDefaults() async {
        let planList = [
            AccountPlanEntity(type: .proII, price: 2),
            AccountPlanEntity(type: .proI, price: 1),
            AccountPlanEntity(type: .proIII, price: 3)
        ]
        let (sut, _) = makeSUT(planList: planList)

        await sut.setupPlans()

        XCTAssertEqual(sut.lowestProPlan.type, .proI)
        XCTAssertEqual(sut.lowestProPlan.price, 1)

        XCTAssertTrue(sut.filteredPlanList.contains { $0.type == .free })

        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() {
        let (sut, _) = makeSUT()
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    // MARK: - Plan list
    private func testFilteredPlanList(planList: [AccountPlanEntity], expectedPlans: [AccountPlanEntity], forCycle cycle: SubscriptionCycleEntity) async {
        let (sut, _) = makeSUT(planList: planList)
        
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
    
    func testRestorePurchaseAlert_successRestore_shouldShowAlertForSuccessRestore() throws {
        try testRestorePurchaseAlert(shouldShowAlertFor: .success)
    }

    func testRestorePurchaseAlert_incompleteRestore_shouldShowAlertForIncompleteRestore() throws {
        try testRestorePurchaseAlert(shouldShowAlertFor: .incomplete)
    }

    func testRestorePurchaseAlert_failedRestore_shouldShowAlertForFailedRestore() throws {
        try testRestorePurchaseAlert(shouldShowAlertFor: .failed)
    }

    func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() {
        let (sut, _) = makeSUT()
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Purchase
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let (sut, mockUseCase) = makeSUT(planList: planList)
        
        await sut.setupPlans()
        sut.setSelectedPlan(proI_monthly)
        
        sut.purchaseSelectedPlan()
        await sut.purchasePlanTask?.value
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }
    
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

    // MARK: - Helper

    private func makeSUT(
        planList: [AccountPlanEntity] = [],
        tracker: AnalyticsTracking = MockTracker(),
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
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
            viewProPlanAction: {},
            router: router
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, mockPurchaseUseCase)
    }
}
