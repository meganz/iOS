import Accounts
import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGASwift
import MEGATest
import XCTest

final class UpgradeAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    // MARK: - Init
    
    @MainActor func testInit_setUpPlansForFreeAccount_shouldSetupPlanData() async {
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let sut = await makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free), planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .free)
        XCTAssertEqual(sut.recommendedPlanType, .proI)
    }
    
    @MainActor func testInit_setUpPlansForProAccount_recurringMonthly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_monthly, .proII_monthly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    @MainActor func testInit_setUpPlansForProAccount_recurringYearly_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    @MainActor func testInit_setUpPlansForProAccount_oneTimePurchase_shouldSetupPlanData() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
        XCTAssertEqual(sut.currentPlan?.type, .proI)
        XCTAssertEqual(sut.recommendedPlanType, .proII)
    }
    
    // MARK: - Current plan
    @MainActor func testCurrentPlanValue_freePlan_shouldBeFreePlan() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)

        XCTAssertEqual(sut.currentPlan, .freePlan)
    }
    
    @MainActor func testCurrentPlanValue_freePlan_shouldNotBeNil() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)

        XCTAssertNotEqual(sut.currentPlan, nil)
    }
    
    @MainActor func testCurrentPlanName_shouldMatchCurrentPlanName() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.currentPlanName, "Free")
    }
    
    @MainActor func testCurrentPlanValue_shouldMatchCurrentPlan() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.currentPlan, .proI_monthly)
    }
    
    @MainActor func testCurrentPlanValue_notMatched_shouldBeFailed() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertNotEqual(sut.currentPlan, .proI_yearly)
        XCTAssertNotEqual(sut.currentPlan, .proI_monthly)
    }
    
    // MARK: - Recommended plan
    @MainActor func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanFree_shouldBeProI() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }
    
    @MainActor func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanLite_shouldBeProI() async {
        let details = AccountDetailsEntity.build(proLevel: .lite)
        
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }
    
    @MainActor func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProI_shouldBeProII() async {
        let details = AccountDetailsEntity.build(proLevel: .proI)
        
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    @MainActor func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProII_shouldBeProIII() async {
        let details = AccountDetailsEntity.build(proLevel: .proII)
        
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, .proIII)
    }
    
    @MainActor func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProIII_shouldHaveNoRecommendedPlanType() async {
        let details = AccountDetailsEntity.build(proLevel: .proIII)
        
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertNil(sut.recommendedPlanType)
        XCTAssertNil(sut.selectedPlanType)
    }
    
    @MainActor func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProLite_shouldBeProI() async {
        let planList: [PlanEntity] = [.proLite_monthly, .proI_monthly, .proII_monthly, .proIII_monthly]
        let sut = await makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    @MainActor func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProI_shouldBeProII() async {
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proIII_monthly]
        let sut = await makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    @MainActor func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProII_shouldBeProIII() async {
        let planList: [PlanEntity] = [.proII_monthly, .proIII_monthly]
        let sut = await makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
    }
    
    @MainActor func testRecommendedPlan_viewTypeIsOnboarding_withLowestPlanProIII_shouldHaveNoRecommendedPlan() async {
        let planList: [PlanEntity] = [.proIII_monthly]
        let sut = await makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            planList: planList,
            viewType: .onboarding
        )
        
        XCTAssertNil(sut.recommendedPlanType)
        XCTAssertNil(sut.selectedPlanType)
    }
    
    // MARK: - Selected plan type
    @MainActor func testSelectedPlanTypeName_shouldMatchSelectedPlanName() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanName, PlanEntity.proI_monthly.name)
    }
    
    @MainActor func testSelectedPlanType_freeAccount_shouldMatchSelectedPlanType() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertEqual(sut.selectedPlanType, PlanEntity.proI_monthly.type)
    }
    
    @MainActor func testSelectedPlanType_recurringPlanAccount_selectCurrentPlan_shouldNotSelectPlanType() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertNotEqual(sut.selectedPlanType, PlanEntity.proI_monthly.type)
    }
    
    // MARK: - Selected term tab
    @MainActor func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    @MainActor func testSelectedCycleTab_oneTimePurchaseMonthly_defaultShouldBeYearly() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    @MainActor func testSelectedCycleTab_oneTimePurchaseYearly_defaultShouldBeYearly() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    @MainActor func testSelectedCycleTab_recurringPlanYearly_defaultShouldBeYearly() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    @MainActor func testSelectedCycleTab_recurringPlanMonthly_defaultShouldBeMonthly() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        XCTAssertEqual(sut.selectedCycleTab, .monthly)
    }
    
    // MARK: - Buy button
    @MainActor func testIsShowBuyButton_freeAccount_shouldBeTrue() async {
        let details = AccountDetailsEntity.build(proLevel: .free, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proII_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proII_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    @MainActor func testIsShowBuyButton_selectedPlanTypeOnMonthly_thenSwitchedToYearlyTab_shouldBeTrue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proII_monthly)
        sut.selectedCycleTab = .yearly
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    @MainActor func testIsShowBuyButton_selectedPlanTypeOnYearly_thenSwitchedToMonthlyTab_shouldBeTrue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proII_yearly)
        sut.selectedCycleTab = .monthly
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    @MainActor func testIsShowBuyButtonWithRecurringPlanMonthly_selectSamePlanTypeOnYearlyTab_thenSwitchedToMonthlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.selectedCycleTab = .yearly
        sut.setSelectedPlan(.proI_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .monthly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    @MainActor func testIsShowBuyButtonWithRecurringPlanYearly_selectSamePlanTypeOnMonthlyTab_thenSwitchedToYearlyTab_shouldToggleValue() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.selectedCycleTab = .monthly
        sut.setSelectedPlan(.proI_monthly)
        XCTAssertTrue(sut.isShowBuyButton)
        
        sut.selectedCycleTab = .yearly
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    // MARK: - Plan list
    @MainActor func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.selectedCycleTab = .monthly
        XCTAssertEqual(sut.filteredPlanList, [.proI_monthly, .proII_monthly])
    }
    
    @MainActor func testFilteredPlanList_yearly_shouldReturnYearlyPlans() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.selectedCycleTab = .yearly
        XCTAssertEqual(sut.filteredPlanList, [.proI_yearly, .proII_yearly])
    }
    
    // MARK: - Restore
    @MainActor func testRestore_tappedRestoreButton_shouldCallRestorePlan() async {
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase()
        let sut = await makeSUT(
            purchaseUseCase: mockPurchaseUseCase,
            accountDetails: AccountDetailsEntity.build(proLevel: .free)
        )
        
        sut.didTap(.restorePlan)
        XCTAssertTrue(mockPurchaseUseCase.restorePurchaseCalled == 1)
    }
    
    @MainActor func testRestorePurchaseAlert_successRestore_shouldShowAlertForSuccessRestore() async throws {
        let sut = await makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.success))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore success")
            return
        }
        XCTAssertEqual(status, .success)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor func testRestorePurchaseAlert_incompleteRestore_shouldShowAlertForIncompleteRestore() async throws {
        let sut = await makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.incomplete))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore incomplete")
            return
        }
        XCTAssertEqual(status, .incomplete)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor func testRestorePurchaseAlert_failedRestore_shouldShowAlertForFailedRestore() async throws {
        let sut = await makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(UpgradeAccountPlanAlertType.restore(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    @MainActor func testRestorePurchaseAlert_setNilAlertType_shouldNotShowAnyAlert() async {
        let sut = await makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Validate active subscriptions
    @MainActor func testPurchasePlan_validateActiveSubscriptions_haveActiveCancellableSubscription_shouldThrowHaveCancellablePlanError() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveCancellablePlan)
        }
    }
    
    @MainActor func testPurchasePlan_validateActiveSubscriptions_haveActiveNonCancellableSubscription_shouldThrowHaveNonCancellablePlanError() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: nonCancellableSubscriptionMethod)
        let sut = await makeSUT(accountDetails: details)
        
        XCTAssertThrowsError(try sut.validateActiveSubscriptions()) { error in
            XCTAssertEqual(error as? ActiveSubscriptionError, ActiveSubscriptionError.haveNonCancellablePlan)
        }
    }
    
    // MARK: - Cancel active subscription
    @MainActor func testCancelActiveSubscription_shouldCancelSubscription_shouldSuccessValidateSubscription() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: cancellableSubscriptionMethod)
        let expectedAccountPlan = AccountDetailsEntity.build(proLevel: .proI, subscriptionStatus: .none, subscriptionMethodId: .balance)
        let mockSubscriptionsUseCase = MockSubscriptionsUseCase(requestResult: .success)
        let sut = await makeSUT(
            subscriptionsUseCase: mockSubscriptionsUseCase,
            accountDetails: details,
            accountDetailsResult: .success(expectedAccountPlan)
        )
        
        await sut.cancelActiveCancellableSubscription()
        XCTAssertTrue(mockSubscriptionsUseCase.cancelSubscriptions_calledTimes == 1)
        
        do {
            try sut.validateActiveSubscriptions()
        } catch {
            XCTFail("Active Subscription error \(error) is not expected.")
        }
    }
    
    // MARK: - Purchase
    @MainActor func testPurchasePlan_shouldCallPurchasePlan() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(
            accountPlanProducts: [.proI_monthly, .proII_monthly, .proI_yearly, .proII_yearly]
        )
        let sut = await makeSUT(
            purchaseUseCase: mockPurchaseUseCase,
            accountDetails: details
        )
        
        sut.setSelectedPlan(.proI_monthly)
        
        sut.didTap(.buyPlan)
        await sut.buyPlanTask?.value
        XCTAssertTrue(mockPurchaseUseCase.purchasePlanCalled == 1)
    }
    
    @MainActor func testPurchasePlanAlert_failedPurchase_shouldShowAlertForFailedPurchase() async throws {
        let sut = await makeSUT(accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        sut.setAlertType(UpgradeAccountPlanAlertType.purchase(.failed))
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .purchase(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Purchase failed")
            return
        }
        XCTAssertEqual(status, .failed)
        XCTAssertTrue(sut.isAlertPresented)
    }
    
    // MARK: - Purchase updates
    @MainActor func testStartPurchaseUpdatesMonitoring_purchasePlanResultUpdates_whenSuccessful_shouldHandleRequest() async throws {
        let (stream, continuation) = AsyncStream<Result<Void, AccountPlanErrorEntity>>.makeStream()
        let mockUsecase = MockAccountPlanPurchaseUseCase(purchasePlanResultUpdates: stream.eraseToAnyAsyncSequence())
        let sut = await makeSUT(purchaseUseCase: mockUsecase, accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        trackTaskCancellation { try await sut.startPurchaseUpdatesMonitoring() }
        
        let loadingExp = expectation(description: "Stop loading")
        sut.$isLoading
            .dropFirst()
            .sink { isLoading in
                XCTAssertFalse(isLoading)
                loadingExp.fulfill()
            }.store(in: &subscriptions)
        
        let dismissExp = expectation(description: "Dismiss view")
        sut.$isDismiss
            .dropFirst()
            .sink { isDismiss in
                XCTAssertTrue(isDismiss)
                dismissExp.fulfill()
            }.store(in: &subscriptions)
        
        continuation.yield(.success)
        continuation.finish()
        
        await fulfillment(of: [loadingExp, dismissExp], timeout: 1.5)
    }
    
    @MainActor private func assertFailedPurchasePlanResultUpdate_shouldHandleRequest(error: AccountPlanErrorEntity) async -> UpgradeAccountPlanAlertType? {
        let (stream, continuation) = AsyncStream<Result<Void, AccountPlanErrorEntity>>.makeStream()
        let mockUsecase = MockAccountPlanPurchaseUseCase(purchasePlanResultUpdates: stream.eraseToAnyAsyncSequence())
        let sut = await makeSUT(purchaseUseCase: mockUsecase, accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        trackTaskCancellation { try await sut.startPurchaseUpdatesMonitoring() }
        
        let exp = expectation(description: "Present error alert")
        exp.isInverted = error.errorCode == 2 // If payment cancelled
        sut.$isAlertPresented
            .dropFirst()
            .sink { isPresented in
                XCTAssertTrue(isPresented)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        continuation.yield(.failure(error))
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 1.0)
        
        return sut.alertType
    }
    
    @MainActor func testStartPurchaseUpdatesMonitoring_purchasePlanResultUpdates_whenFailedAndNotCancelled_shouldHandleRequest() async throws {
        let alertTypeResult = await assertFailedPurchasePlanResultUpdate_shouldHandleRequest(
            error: .init(errorCode: randomAccountPlanPurchaseErrorCode(excludingCancelError: true), errorMessage: nil)
        )
        
        let newAlertType = try XCTUnwrap(alertTypeResult)
        guard case .purchase(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Purchase failed")
            return
        }
        
        XCTAssertEqual(status, .failed)
    }
    
    @MainActor func testStartPurchaseUpdatesMonitoring_purchasePlanResultUpdates_whenFailedAndCancelled_shouldHandleRequest() async throws {
        let paymentCancelledErrorCode = 2
        let alertTypeResult = await assertFailedPurchasePlanResultUpdate_shouldHandleRequest(
            error: .init(errorCode: paymentCancelledErrorCode, errorMessage: nil)
        )
        
        XCTAssertNil(alertTypeResult)
    }
    
    @MainActor private func assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: RestorePurchaseStateEntity) async throws -> UpgradeAccountPlanAlertType.AlertStatus {
        let (stream, continuation) = AsyncStream<RestorePurchaseStateEntity>.makeStream()
        let mockUsecase = MockAccountPlanPurchaseUseCase(restorePurchaseUpdates: stream.eraseToAnyAsyncSequence())
        let sut = await makeSUT(purchaseUseCase: mockUsecase, accountDetails: AccountDetailsEntity.build(proLevel: .free))
        
        trackTaskCancellation { try await sut.startRestoreUpdatesMonitoring() }
        
        let exp = expectation(description: "Present alert")
        sut.$isAlertPresented
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        continuation.yield(restoreUpdate)
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertTrue(sut.isAlertPresented)
        
        let newAlertType = try XCTUnwrap(sut.alertType)
        guard case .restore(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Restore type")
            throw MockError()
        }
        return status
    }
    
    @MainActor func testStartPurchaseUpdatesMonitoring_restorePurchaseUpdates_whenSuccessful_shouldShowAlert() async throws {
        let alertTypeResult = try await assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: .success)
        XCTAssertEqual(alertTypeResult, .success)
    }
    
    @MainActor func testStartPurchaseUpdatesMonitoring_restorePurchaseUpdates_whenIncomplete_shouldShowAlert() async throws {
        let alertTypeResult = try await assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: .incomplete)
        XCTAssertEqual(alertTypeResult, .incomplete)
    }
    
    @MainActor func testStartPurchaseUpdatesMonitoring_restorePurchaseUpdates_whenFailed_shouldShowAlert() async throws {
        let alertTypeResult = try await assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: .failed(.random))
        XCTAssertEqual(alertTypeResult, .failed)
    }
    
    // MARK: - Snackbar
    @MainActor func testSnackBar_selectedCurrentRecurringAccount_shouldShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertEqual(sut.snackBar?.message, PlanSelectionSnackBarType.currentRecurringPlanSelected.title)
    }
    
    @MainActor func testSnackBar_selectedCurrentOneTimeAccount_shouldNotShowSnackBar() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proI_monthly)
        
        XCTAssertNil(sut.snackBar)
    }

    // MARK: - Ads
    @MainActor func testSetupExternalAds_adsEnabledAndExternalAdsDisabled_shouldBeFalse() async {
        let sut = await makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            abTestProvider: MockABTestProvider(list: [.ads: .variantA, .externalAds: .baseline])
        )
        
        await sut.setUpExternalAds()
        
        XCTAssertFalse(sut.isExternalAdsActive)
    }
    
    @MainActor func testSetupExternalAds_adsEnabledAndExternalAdsEnabled_shouldBeTrue() async {
        let sut = await makeSUT(
            accountDetails: AccountDetailsEntity.build(proLevel: .free),
            abTestProvider: MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA])
        )
        
        await sut.setUpExternalAds()
        
        XCTAssertTrue(sut.isExternalAdsActive)
    }
    
    // - MARK: Track events
    @MainActor func testPurchasePlan_purchaseProI_shouldTrackEvent() async {
        let harness = await Harness()
        await harness.testBuyPlan(.proI_yearly, shouldTrack: BuyProIEvent())
    }
    
    @MainActor func testPurchasePlan_purchaseProII_shouldTrackEvent() async {
        let harness = await Harness()
        await harness.testBuyPlan(.proII_yearly, shouldTrack: BuyProIIEvent())
    }
    
    @MainActor func testPurchasePlan_purchaseProIII_shouldTrackEvent() async {
        let harness = await Harness()
        await harness.testBuyPlan(.proIII_yearly, shouldTrack: BuyProIIIEvent())
    }
    
    @MainActor func testPurchasePlan_purchaseProLite_shouldTrackEvent() async {
        let harness = await Harness()
        await harness.testBuyPlan(.proLite_yearly, shouldTrack: BuyProLiteEvent())
    }
    
    @MainActor func testCancel_tappedCancelButton_shouldTrackCancelUpgradeEvent() async {
        let harness = await Harness()
        harness.testCancelUpgrade()
    }
    
    @MainActor func testViewLoad_shouldTrackScreenViewEvent() async {
        let harness = await Harness()
        harness.testViewOnLoad()
    }
    
    // MARK: - Helper
    @MainActor func makeSUT(
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol = MockSubscriptionsUseCase(requestResult: .failure(.generic)),
        purchaseUseCase: (any AccountPlanPurchaseUseCaseProtocol)? = nil,
        accountDetails: AccountDetailsEntity,
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        planList: [PlanEntity] = [],
        abTestProvider: MockABTestProvider = MockABTestProvider(list: [.ads: .variantA, .externalAds: .variantA]),
        tracker: MockTracker = MockTracker(),
        viewType: UpgradeAccountPlanViewType = .upgrade,
        file: StaticString = #file,
        line: UInt = #line
    ) async -> UpgradeAccountPlanViewModel {
        let mockPurchaseUseCase = purchaseUseCase ?? MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let mockAccountUseCase = MockAccountUseCase(accountDetailsResult: accountDetailsResult)
        let router = MockUpgradeAccountPlanRouter()
        let sut = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: mockAccountUseCase,
            purchaseUseCase: mockPurchaseUseCase,
            subscriptionsUseCase: subscriptionsUseCase,
            abTestProvider: abTestProvider,
            tracker: tracker,
            viewType: viewType,
            router: router
        )
        
        await sut.setupPlans()
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        
        return sut
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
    
    private func randomAccountPlanPurchaseErrorCode(excludingCancelError: Bool = false) -> Int {
        var storePurchaseErrorCodes = [0, // unknown
                                       1, // client invalid
                                       2, // payment cancelled
                                       3, // payment invalid
                                       4] // payment not allowed
        
        if excludingCancelError {
            storePurchaseErrorCodes.remove(object: 2)
        }
        return storePurchaseErrorCodes.randomElement() ?? 0
    }
    
    @MainActor final class Harness {
        let sut: UpgradeAccountPlanViewModel
        let tracker = MockTracker()
        
        init(
            details: AccountDetailsEntity = AccountDetailsEntity.build(proLevel: .free),
            planList: [PlanEntity] = [.freePlan, .proI_yearly, .proII_yearly, .proIII_yearly, .proLite_yearly]
        ) async {
            self.sut = await UpgradeAccountPlanViewModelTests().makeSUT(
                accountDetails: details,
                planList: planList,
                tracker: tracker
            )
        }
        
        func testBuyPlan(_ plan: PlanEntity, shouldTrack event: any EventIdentifier) async {
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
