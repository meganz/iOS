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
    
    // MARK: - Init
    func testInit_registerDelegates_shouldRegisterDelegates() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let (sut, mockUseCase) = makeSUT(
            accountDetails: details
        )
        
        await sut.registerDelegateTask?.value
        XCTAssertTrue(mockUseCase.registerRestoreDelegateCalled == 1)
    }
    
    func testInit_setUpPlansForFreeAccount_shouldSetupPlanData() async {
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free), planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .free)
        XCTAssertEqual(sut.recommendedPlanType, .proI)
    }
    
    func testInit_setUpPlansForProAccount_recurringMonthly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_monthly, .proII_monthly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    func testInit_setUpPlansForProAccount_recurringYearly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    func testInit_setUpPlansForProAccount_oneTimePurchase_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    // MARK: - Current plan
    func testCurrentPlanValue_freePlan_shouldBeFreePlan() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        
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

    func testCurrentPlanValue_freePlan_shouldNotBeNil() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        
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
    
    func testCurrentPlanName_shouldMatchCurrentPlanName() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        
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
    
    func testCurrentPlanValue_shouldMatchCurrentPlan() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        
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
    
    func testCurrentPlanValue_notMatched_shouldBeFailed() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        
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
    
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProLite_shouldBeProI() async {
        let planList: [AccountPlanEntity] = [.proLite_monthly, .proI_monthly, .proII_monthly, .proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProI_shouldBeProII() async {
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_monthly, .proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProII_shouldBeProIII() async {
        let planList: [AccountPlanEntity] = [.proII_monthly, .proIII_monthly]
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        await sut.setUpPlanTask?.value

        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProIII_shouldHaveNoRecommendedPlan() async {
        let planList: [AccountPlanEntity] = [.proIII_monthly]
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
    func testSelectedPlanTypeName_shouldMatchSelectedPlanName() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanName, AccountPlanEntity.proI_monthly.name)
    }
    
    func testSelectedPlanType_freeAccount_shouldMatchSelectedPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanType, AccountPlanEntity.proI_monthly.type)
    }

    func testSelectedPlanType_recurringPlanAccount_selectCurrentPlan_shouldNotSelectPlanType() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]

        let exp = expectation(description: "Setting Current plan")
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(.proI_monthly)
        XCTAssertNotEqual(sut.selectedPlanType, AccountPlanEntity.proI_monthly.type)
    }

    // MARK: - Selected term tab
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .free)

        let (sut, _) = makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }

    func testSelectedCycleTab_oneTimePurchaseMonthly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_yearly]

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

    func testSelectedCycleTab_oneTimePurchaseYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_yearly]

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

    func testSelectedCycleTab_recurringPlanYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_yearly]

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

    func testSelectedCycleTab_recurringPlanMonthly_defaultShouldBeMonthly() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_yearly]

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
    func testIsShowBuyButton_freeAccount_shouldBeTrue() {
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        let planList: [AccountPlanEntity] = [.proII_monthly, .proII_yearly]

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

    func testIsShowBuyButton_selectedPlanTypeOnMonthly_thenSwitchedToYearlyTab_shouldBeTrue() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]

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
    
    func testIsShowBuyButton_selectedPlanTypeOnYearly_thenSwitchedToMonthlyTab_shouldBeTrue() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]

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
    
    func testIsShowBuyButtonWithRecurringPlanMonthly_selectSamePlanTypeOnYearlyTab_thenSwitchedToMonthlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .yearly
        sut.setSelectedPlan(.proI_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .monthly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    func testIsShowBuyButtonWithRecurringPlanYearly_selectSamePlanTypeOnMonthlyTab_thenSwitchedToYearlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        
        sut.selectedCycleTab = .monthly
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .yearly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    // MARK: - Plan list
    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
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
    
    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
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
    func testRestore_tappedRestoreButton_shouldCallRestorePlan() async {
        let (sut, mockUseCase) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.didTap(.restorePlan)
        XCTAssertTrue(mockUseCase.restorePurchaseCalled == 1)
    }
    
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
    
    func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() {
        let (sut, _) = makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Validate active subscriptions
    func testPurchasePlan_validateActiveSubscriptions_haveActiveCancellableSubscription_shouldThrowHaveCancellablePlanError() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let (sut, _) = makeSUT(accountDetails: details)
        
        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveCancellablePlan)
        }
    }
    
    func testPurchasePlan_validateActiveSubscriptions_haveActiveNonCancellableSubscription_shouldThrowHaveNonCancellablePlanError() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: nonCancellableSubscriptionMethod)
        let (sut, _) = makeSUT(accountDetails: details)

        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveNonCancellablePlan)
        }
    }
    
    // MARK: - Cancel active subscription
    func testCancelActiveSubscription_shouldCancelSubscription_shouldSuccessValidateSubscription() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let expectedAccountPlan = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .none, subscriptionMethodId: .balance)
        let (sut, mockPurchaseUseCase) = makeSUT(
            accountDetails: details,
            accountDetailsResult: .success(expectedAccountPlan)
        )
        
        await sut.cancelActiveCancellableSubscription()
        XCTAssertTrue(mockPurchaseUseCase.cancelCreditCardSubscriptions == 1)
        
        do {
            try sut.validateActiveSubscriptions()
        } catch {
            XCTFail("Active Subscription error \(error) is not expected.")
        }
    }
    
    // MARK: - Purchase
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
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
    func testSnackBar_selectedCurrentRecurringAccount_shouldShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertTrue(sut.isShowSnackBar)
        XCTAssertEqual(sut.snackBarType, .currentRecurringPlanSelected)
    }
    
    func testSnackBar_selectedCurrentOneTimeAccount_shouldNotShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertFalse(sut.isShowSnackBar)
        XCTAssertEqual(sut.snackBarType, .none)
    }
    
    func testSnackBarType_isShowSnackBarSetToFalse_shouldBeNone() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [AccountPlanEntity] = [.proI_monthly, .proI_yearly]
        let (sut, _) = makeSUT(accountDetails: details, planList: planList)
        
        await sut.setUpPlanTask?.value
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertTrue(sut.isShowSnackBar)
        
        let exp = expectation(description: "Set snackBarViewModel snackBarViewModel to false")
        let snackBarViewModel = sut.snackBarViewModel()
        snackBarViewModel.$isShowSnackBar
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)

        snackBarViewModel.isShowSnackBar = false
        await fulfillment(of: [exp], timeout: 0.5)
        XCTAssertEqual(sut.snackBarType, .none)
    }
    
    // MARK: - Ads
    
    func testSetupExternalAds_adsEnabledAndExternalAdsDisabled_shouldBeFalse() async {
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            abTestProvider: MockABTestProvider(list: [.ads: .variantA, .externalAds: .baseline])
        )
        
        await sut.setUpExternalAds()
        
        XCTAssertFalse(sut.isExternalAdsActive)
    }
    
    func testSetupExternalAds_adsEnabledAndExternalAdsEnabled_shouldBeTrue() async {
        let (sut, _) = makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            abTestProvider: MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA])
        )
        
        await sut.setUpExternalAds()
        
        XCTAssertTrue(sut.isExternalAdsActive)
    }
    
    // - MARK: Track events
    func testPurchasePlan_purchaseProI_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proI_yearly, shouldTrack: BuyProIEvent())
    }
    
    func testPurchasePlan_purchaseProII_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proII_yearly, shouldTrack: BuyProIIEvent())
    }
    
    func testPurchasePlan_purchaseProIII_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proIII_yearly, shouldTrack: BuyProIIIEvent())
    }
    
    func testPurchasePlan_purchaseProLite_shouldTrackEvent() async {
        let harness = Harness()
        await harness.testBuyPlan(.proLite_yearly, shouldTrack: BuyProLiteEvent())
    }
    
    func testCancel_tappedCancelButton_shouldTrackCancelUpgradeEvent() {
        let harness = Harness()
        harness.testCancelUpgrade()
    }
    
    func testViewLoad_shouldTrackScreenViewEvent() {
        let harness = Harness()
        
    }
    
    // MARK: - Helper
    func makeSUT(
        accountDetails: AccountDetailsEntity,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        planList: [AccountPlanEntity] = [],
        abTestProvider: MockABTestProvider = MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA]),
        tracker: MockTracker = MockTracker(),
        viewType: UpgradeAccountPlanViewType = .upgrade
    ) -> (UpgradeAccountPlanViewModel, MockAccountPlanPurchaseUseCase) {
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let mockAccountUseCase = MockAccountUseCase(accountDetailsResult: accountDetailsResult)
        let router = MockUpgradeAccountPlanRouter()
        let sut = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: mockAccountUseCase,
            purchaseUseCase: mockPurchaseUseCase,
            abTestProvider: abTestProvider,
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
    
    class Harness {
        let sut: UpgradeAccountPlanViewModel
        let tracker = MockTracker()
        
        init(
            details: AccountDetailsEntity = AccountDetailsEntity.build(proLevel: .free),
            planList: [AccountPlanEntity] = [.freePlan, .proI_yearly, .proII_yearly, .proIII_yearly, .proLite_yearly]
        ) {
            let (sut, _) = UpgradeAccountPlanViewModelTests().makeSUT(
                accountDetails: details,
                planList: planList,
                tracker: tracker
            )
            self.sut = sut
        }
        
        func testBuyPlan(_ plan: AccountPlanEntity, shouldTrack event: EventIdentifier) async {
            await sut.setUpPlanTask?.value
            sut.setSelectedPlan(plan)
            
            sut.didTap(.buyPlan)
            await sut.buyPlanTask?.value
            
            XCTestCase().assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [event]
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
