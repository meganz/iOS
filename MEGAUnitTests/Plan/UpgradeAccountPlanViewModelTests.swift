import Accounts
import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class UpgradeAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private let storageMax = 20
    
    // MARK: - Init
    @MainActor
    func testInit_registerDelegates_shouldRegisterDelegates() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let (sut, mockUseCase) = makeSUT(
            accountDetails: details
        )
        
        await sut.registerDelegateTask?.value
        XCTAssertTrue(mockUseCase.registerRestoreDelegateCalled == 1)
    }
    
    @MainActor
    func testInit_setUpPlansForFreeAccount_shouldSetupPlanData() async {
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free), planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .free)
        XCTAssertEqual(sut.recommendedPlanType, .proI)
    }
    
    @MainActor
    func testInit_setUpPlansForProAccount_recurringMonthly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_monthly, .proII_monthly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    @MainActor
    func testInit_setUpPlansForProAccount_recurringYearly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    @MainActor
    func testInit_setUpPlansForProAccount_oneTimePurchase_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    // MARK: - Current plan
    @MainActor
    func testCurrentPlanValue_freePlan_shouldBeFreePlan() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, .freePlan)
    }

    @MainActor
    func testCurrentPlanValue_freePlan_shouldNotBeNil() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, nil)
    }
    
    @MainActor
    func testCurrentPlanName_shouldMatchCurrentPlanName() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlanName, "Free")
    }
    
    @MainActor
    func testCurrentPlanValue_shouldMatchCurrentPlan() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, .proI_monthly)
    }
    
    @MainActor
    func testCurrentPlanValue_notMatched_shouldBeFailed() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, .proI_yearly)
        XCTAssertNotEqual(sut.currentPlan, .proI_monthly)
    }
    
    // MARK: - Recommended plan
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanFree_shouldBeProI() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }

    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanLite_shouldBeProI() {
        let details = AccountDetailsEntity.build(proLevel: .lite)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }
    
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProI_shouldBeProII() {
        let details = AccountDetailsEntity.build(proLevel: .proI)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProII_shouldBeProIII() {
        let details = AccountDetailsEntity.build(proLevel: .proII)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, .proIII)
    }
    
    @MainActor
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProIII_shouldHaveNoRecommendedPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .proIII)
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNil(sut.recommendedPlanType)
        XCTAssertNil(sut.selectedPlanType)
    }
    
    @MainActor
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProLite_shouldBeProI() async {
        let planList: [PlanEntity] = [.proLite_monthly, .proI_monthly, .proII_monthly, .proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    @MainActor
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProI_shouldBeProII() async {
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    @MainActor
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProII_shouldBeProIII() async {
        let planList: [PlanEntity] = [.proII_monthly, .proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    @MainActor
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProIII_shouldHaveNoRecommendedPlan() async {
        let planList: [PlanEntity] = [.proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertNil(sut.recommendedPlanType)
        XCTAssertNil(sut.selectedPlanType)
    }
    
    // MARK: - Selected plan type
    @MainActor
    func testSelectedPlanTypeName_shouldMatchSelectedPlanName() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanName, PlanEntity.proI_monthly.name)
    }
    
    @MainActor
    func testSelectedPlanType_freeAccount_shouldMatchSelectedPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanType, PlanEntity.proI_monthly.type)
    }

    @MainActor
    func testSelectedPlanType_recurringPlanAccount_selectCurrentPlan_shouldNotSelectPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proI_monthly)
        XCTAssertNotEqual(sut.selectedPlanType, PlanEntity.proI_monthly.type)
    }

    // MARK: - Selected term tab
    @MainActor
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .free)

        let (sut, _) = makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_oneTimePurchaseMonthly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_oneTimePurchaseYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_recurringPlanYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    @MainActor
    func testSelectedCycleTab_recurringPlanMonthly_defaultShouldBeMonthly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Plan Term Tab")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$selectedCycleTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
    }

    // MARK: - Buy button
    @MainActor
    func testIsShowBuyButton_freeAccount_shouldBeTrue() {
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proII_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proII_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
    }

    @MainActor
    func testIsShowBuyButton_selectedPlanTypeOnMonthly_thenSwitchedToYearlyTab_shouldBeTrue() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proII_monthly)
        sut.selectedCycleTab = .yearly
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    @MainActor
    func testIsShowBuyButton_selectedPlanTypeOnYearly_thenSwitchedToMonthlyTab_shouldBeTrue() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proII_yearly)
        sut.selectedCycleTab = .monthly
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    @MainActor
    func testIsShowBuyButtonWithRecurringPlanMonthly_selectSamePlanTypeOnYearlyTab_thenSwitchedToMonthlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .yearly
        sut.setSelectedPlan(.proI_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .monthly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    @MainActor
    func testIsShowBuyButtonWithRecurringPlanYearly_selectSamePlanTypeOnMonthlyTab_thenSwitchedToYearlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .monthly
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .yearly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    // MARK: - Plan list
    @MainActor
    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
        let exp = expectation(description: "Set selected plan term")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.selectedCycleTab = .monthly
        XCTAssertEqual(sut.filteredPlanList, [.proI_monthly, .proII_monthly])
    }
    
    @MainActor
    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
        let exp = expectation(description: "Set selected plan term")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.selectedCycleTab = .yearly
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
    }
    
    // MARK: - Restore
    @MainActor
    func testRestore_tappedRestoreButton_shouldCallRestorePlan() async {
        let (sut, mockUseCase) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.didTap(.restorePlan)
        XCTAssertTrue(mockUseCase.restorePurchaseCalled == 1)
    }
    
    @MainActor
    func testRestorePurchaseAlert_successRestore_shouldShowAlertForSuccessRestore() throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.success))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore success")
            return
        }
        XCTAssertEqual(status, .success)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor
    func testRestorePurchaseAlert_incompleteRestore_shouldShowAlertForIncompleteRestore() throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.incomplete))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore incomplete")
            return
        }
        XCTAssertEqual(status, .incomplete)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor
    func testRestorePurchaseAlert_failedRestore_shouldShowAlertForFailedRestore() throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor
    func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Validate active subscriptions
    @MainActor
    func testPurchasePlan_validateActiveSubscriptions_haveActiveCancellableSubscription_shouldThrowHaveCancellablePlanError() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let (sut, _) = makeSUT(accountDetails: details)
        
        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveCancellablePlan)
        }
    }
    
    @MainActor
    func testPurchasePlan_validateActiveSubscriptions_haveActiveNonCancellableSubscription_shouldThrowHaveNonCancellablePlanError() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: nonCancellableSubscriptionMethod)
        let (sut, _) = makeSUT(accountDetails: details)

        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveNonCancellablePlan)
        }
    }
    
    // MARK: - Cancel active subscription
    @MainActor
    func testCancelActiveSubscription_shouldCancelSubscription_shouldSuccessValidateSubscription() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let expectedAccountPlan = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .none, subscriptionMethodId: .balance)
        let mockSubscriptionsUseCase = MockSubscriptionsUseCase(requestResult: .success)
        let (sut, _) = makeSUT(
            subscriptionsUseCase: mockSubscriptionsUseCase,
            accountDetails: details,
            accountDetailsResult: .success(expectedAccountPlan)
        )
        
        await sut.cancelActiveCancellableSubscription()
        XCTAssertTrue(mockSubscriptionsUseCase.cancelSubscriptionsWithReasonString_calledTimes == 1)
        
        do {
            try sut.validateActiveSubscriptions()
        } catch {
            XCTFail("Active Subscription error \(error) is not expected.")
        }
    }
    
    // MARK: - Purchase
    @MainActor
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        let (sut, mockUseCase) = makeSUT(
            accountDetails: details,
            planList: planList
        )
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        sut.didTap(.buyPlan)
        await sut.buyPlanTask?.value
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }
    
    @MainActor
    func testPurchasePlanAlert_failedPurchase_shouldShowAlertForFailedPurchase() async throws {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        await sut.setUpPlanTask?.value
        
        sut.setAlertType(UpgradeAccountPlanAlertType.purchase(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .purchase(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Purchase failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    // MARK: - Snackbar
    @MainActor
    func testSnackBar_selectedCurrentRecurringAccount_shouldShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertEqual(sut.snackBar?.message, PlanSelectionSnackBarType.currentRecurringPlanSelected.title)
    }
    
    @MainActor
    func testSnackBar_selectedCurrentOneTimeAccount_shouldNotShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertNil(sut.snackBar)
    }
        
    // MARK: - Ads
    @MainActor func testSetupExternalAds_externalAdsEnabled_shouldBeTrue() {
        assertSetupExternalAds(isExternalAdsFlagEnabled: true)
    }
    
    @MainActor func testSetupExternalAds_externalAdsDisabled_shouldBeFalse() {
        assertSetupExternalAds(isExternalAdsFlagEnabled: false)
    }
    
    @MainActor func assertSetupExternalAds(isExternalAdsFlagEnabled: Bool) {
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            isExternalAdsFlagEnabled: isExternalAdsFlagEnabled
        )
        
        XCTAssertEqual(sut.isExternalAdsActive, isExternalAdsFlagEnabled)
    }
    
    // - MARK: Track events
    @MainActor
    func testPurchasePlan_purchaseProI_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proI_yearly, shouldTrack: [BuyProIEvent()])
    }
    
    @MainActor
    func testPurchasePlan_purchaseProII_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proII_yearly, shouldTrack: [BuyProIIEvent()])
    }
    
    @MainActor
    func testPurchasePlan_purchaseProIII_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proIII_yearly, shouldTrack: [BuyProIIIEvent()])
    }
    
    @MainActor
    func testPurchasePlan_purchaseProLite_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proLite_yearly, shouldTrack: [BuyProLiteEvent()])
    }
    
    @MainActor
    func testCancel_tappedCancelButton_shouldTrackCancelUpgradeEvent() {
        let harness = Harness()
        harness.testCancelUpgrade()
    }
    
    @MainActor
    func testViewLoad_shouldTrackScreenViewEvent() {
        let harness = Harness()
        harness.testViewOnLoad()
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsTrue_shouldTrackButtonTapEventForAdsSurePath() async {
        let harness = Harness(isFromAds: true)
        
        await harness.testBuyPlan(
            .proLite_yearly,
            shouldTrack: [
                AdFreeDialogUpgradeAccountPlanPageBuyButtonPressedEvent(),
                BuyProLiteEvent()
            ]
        )
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsFalseAndEligibleForAdsEvent_shouldTrackButtonTapEventForAdsMaybePath() async {
        // Ads was closed within the last two days and
        // only less than half of storage quota is used
        let largestValidSize = (storageMax - 1) / 2
        let lessThanHalfOfStorage = Int.random(in: 0...largestValidSize)
        await assertAdsEventForMaybePath(
            storageMax: storageMax,
            storageUsed: lessThanHalfOfStorage,
            lastCloseAdsDate: Date(),
            expectedAdsEvent: AdsUpgradeAccountPlanPageBuyButtonPressedEvent()
        )
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsFalseButAdsIsClosedMoreThanTwoDays_shouldNotTrackButtonTapEventForAdsMaybePath() async throws {
        let threeDaysAgo = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: -3, to: Date()))
        
        await assertAdsEventForMaybePath(lastCloseAdsDate: threeDaysAgo, expectedAdsEvent: nil)
    }
    
    @MainActor func testPurchasePlan_whenIsFromAdsIsFalseButHasUsedMoreThanHalfOfStorage_shouldNotTrackButtonTapEventForAdsMaybePath() async throws {
        let moreThanHalfOfStorage = Int.random(in: (storageMax / 2)...storageMax)
        await assertAdsEventForMaybePath(storageMax: storageMax, storageUsed: moreThanHalfOfStorage, expectedAdsEvent: nil)
    }
    
    @MainActor private func assertAdsEventForMaybePath(
        storageMax: Int = 20,
        storageUsed: Int = 0,
        lastCloseAdsDate: Date = Date(),
        expectedAdsEvent: (any EventIdentifier)?
    ) async {
        let accountDetails = AccountDetailsEntity.build(
            storageUsed: Int64(storageUsed),
            storageMax: Int64(storageMax),
            proLevel: .free
        )
        let harness = Harness(details: accountDetails, lastCloseAdsDate: lastCloseAdsDate, isFromAds: false)
        var events: [any EventIdentifier] = []
        
        if let expectedAdsEvent {
            events.append(expectedAdsEvent)
        }
        events.append(BuyProLiteEvent())
        
        await harness.testBuyPlan(
            .proLite_yearly,
            shouldTrack: events
        )
    }
    
    // MARK: - Helper
    @MainActor
    func makeSUT(
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol = MockSubscriptionsUseCase(requestResult: .failure(.generic)),
        accountDetails: AccountDetailsEntity,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        planList: [PlanEntity] = [],
        isExternalAdsFlagEnabled: Bool = true,
        tracker: MockTracker = MockTracker(),
        viewType: UpgradeAccountPlanViewType = .upgrade,
        isFromAds: Bool = false,
        lastCloseAdsDate: Date? = nil
    ) -> (UpgradeAccountPlanViewModel, MockAccountPlanPurchaseUseCase) {
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let mockAccountUseCase = MockAccountUseCase(accountDetailsResult: accountDetailsResult)
        let router = MockUpgradeAccountPlanRouter(isFromAds: isFromAds)
        let preferenceUseCase = MockPreferenceUseCase()
        if let lastCloseAdsDate {
            preferenceUseCase.dict[.lastCloseAdsButtonTappedDate] = lastCloseAdsDate
        }
        let sut = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: mockAccountUseCase,
            purchaseUseCase: mockPurchaseUseCase,
            subscriptionsUseCase: subscriptionsUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.externalAds: isExternalAdsFlagEnabled]),
            preferenceUseCase: preferenceUseCase,
            tracker: tracker,
            viewType: viewType,
            router: router
        )
        return (sut, mockPurchaseUseCase)
    }
    
    private var cancellableSubscriptionMethod: PaymentMethodEntity {
        let methods: [PaymentMethodEntity] = [.ECP, .sabadell, .stripe2]
        return methods.randomElement() ?? .ECP
    }
    
    private var nonCancellableSubscriptionMethod: PaymentMethodEntity {
        let methods: [PaymentMethodEntity] = [.ECP, .sabadell, .stripe2, .itunes, .none]
        let nonCancellableMethod = Set(PaymentMethodEntity.allCases).subtracting(Set(methods))
        return Array(nonCancellableMethod).randomElement() ?? .balance
    }
    
    @MainActor
    class Harness {
        let sut: UpgradeAccountPlanViewModel
        let tracker = MockTracker()
        
        init(
            details: AccountDetailsEntity = AccountDetailsEntity.build(proLevel: .free),
            planList: [PlanEntity] = [.freePlan, .proI_yearly, .proII_yearly, .proIII_yearly, .proLite_yearly],
            lastCloseAdsDate: Date? = nil,
            isFromAds: Bool = false
        ) {
            let (sut, _) = UpgradeAccountPlanViewModelTests().makeSUT(
                accountDetails: details,
                planList: planList,
                tracker: tracker,
                isFromAds: isFromAds,
                lastCloseAdsDate: lastCloseAdsDate
            )
            self.sut = sut
        }
        
        func testBuyPlan(_ plan: PlanEntity, shouldTrack events: [any EventIdentifier]) async {
            await sut.setUpPlanTask?.value
            sut.setSelectedPlan(plan)
            
            sut.didTap(.buyPlan)
            await sut.buyPlanTask?.value
            
            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: events
            )
        }
        
        func testCancelUpgrade() {
            sut.cancelUpgradeButtonTapped()
            
            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [CancelUpgradeMyAccountEvent()]
            )
        }
        
        func testViewOnLoad() {
            sut.onLoad()
            
            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [UpgradeAccountPlanScreenEvent()]
            )
        }
    }
}
