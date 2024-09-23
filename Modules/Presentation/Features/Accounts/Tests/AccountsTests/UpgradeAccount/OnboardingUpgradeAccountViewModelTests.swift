@testable import Accounts
import AccountsMock
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGATest
import XCTest

final class OnboardingUpgradeAccountViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    // MARK: - Init
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
        let expectedLowestPlan = PlanEntity(type: .proI,
                                                   name: "Pro I",
                                                   subscriptionCycle: .monthly, 
                                                   storage: "\(expectedPlanStorage) \(expectedPlanStorageUnit)",
                                                   formattedPrice: "$4.99")
        
        let sut = makeSUT(planList: [expectedLowestPlan])
        await sut.setUpLowestProPlan()
        
        XCTAssertEqual(sut.storageContentMessage, expectedStorageMessage)
    }
    
    func testViewProPlans_onButtonTapped_shouldTrackEvent() async {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.showProPlanView()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                OnboardingUpsellingDialogVariantAViewProPlansButtonEvent()
            ]
        )
    }
    
    func testInit_withEmptyPlanList_shouldSetDefaults() async {
        let sut = makeSUT()
        await sut.setUpLowestProPlan()
        XCTAssertEqual(sut.lowestProPlan, PlanEntity(), "Expected default empty lowest plan")
        XCTAssertEqual(sut.selectedCycleTab, .yearly, "Expected default cycle tab to be yearly")
    }
    
    func testSetUpSubscription_notificationCenterDidReceivedDismissOnboardingProPlanDialog_shouldDismissView() {
        let notificationCenter = NotificationCenter()
        let sut = makeSUT(notificationCenter: notificationCenter)
        
        let exp = expectation(description: "Dismiss view")
        sut.$shouldDismiss
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.setUpSubscription()
        notificationCenter.post(name: .dismissOnboardingProPlanDialog, object: nil)
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertTrue(sut.shouldDismiss)
    }
    
    func testSetupPlans_shouldFetchPlansAndSetDefaults() async {
        let planList = [
            PlanEntity(type: .proII, price: 2),
            PlanEntity(type: .proI, price: 1),
            PlanEntity(type: .proIII, price: 3)
        ]
        let sut = makeSUT(planList: planList)

        await sut.setupPlans()

        XCTAssertEqual(sut.lowestProPlan.type, .proI)
        XCTAssertEqual(sut.lowestProPlan.price, 1)

        XCTAssertTrue(sut.filteredPlanList.contains { $0.type == .free })

        XCTAssertEqual(sut.selectedPlanType, sut.recommendedPlanType)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    func testSelectedCycleTab_freeAccount_defaultShouldBeYearly() async {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.selectedCycleTab, .yearly)
    }
    
    func testIsAdsEnabled_withAdsEnabled_shouldBeTrue() async {
        let sut = makeSUT(isAdsEnabled: true)
        
        XCTAssertTrue(sut.isAdsEnabled)
    }
    
    func testIsAdsEnabled_withAdsDisabled_shouldBefalse() async {
        let sut = makeSUT(isAdsEnabled: false)
        
        XCTAssertFalse(sut.isAdsEnabled)
    }
    
    // MARK: - Plan list
    private func testFilteredPlanList(planList: [PlanEntity], expectedPlans: [PlanEntity], forCycle cycle: SubscriptionCycleEntity) async {
        let sut = makeSUT(planList: planList)
        
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
        let sut = makeSUT()
        
        sut.setAlertType(.restore(status))
        
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
        let sut = makeSUT()
        sut.setAlertType(nil)
        
        XCTAssertNil(sut.alertType)
        XCTAssertFalse(sut.isAlertPresented)
    }
    
    // MARK: - Purchase
    
    func testPurchasePlan_shouldCallPurchasePlan() async {
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let sut = makeSUT(purchaseUseCase: mockUseCase, planList: planList)
        
        await sut.setupPlans()
        sut.setSelectedPlan(proI_monthly)
        
        sut.purchaseSelectedPlan()
        await sut.purchasePlanTask?.value
        XCTAssertTrue(mockUseCase.purchasePlanCalled == 1)
    }
    
    func testPurchasePlan_selectedFreePlan_shouldDismiss() async {
        let planList = [freePlan, proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let sut = makeSUT(planList: planList)
        
        await sut.setupPlans()
        sut.setSelectedPlan(freePlan)
        
        sut.purchaseSelectedPlan()
        await sut.purchasePlanTask?.value
        XCTAssertTrue(sut.shouldDismiss)
    }

    // MARK: - Purchase updates
    func testStartPurchaseUpdatesMonitoring_purchasePlanResultUpdates_whenSuccessful_shouldHandleRequest() async throws {
        let (stream, continuation) = AsyncStream<Result<Void, AccountPlanErrorEntity>>.makeStream()
        let mockUsecase = MockAccountPlanPurchaseUseCase(purchasePlanResultUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(purchaseUseCase: mockUsecase)
        
        trackTaskCancellation { try await sut.startPurchaseUpdatesMonitoring() }
        
        let loadingExp = expectation(description: "Stop loading")
        sut.$isLoading
            .dropFirst()
            .sink { isLoading in
                XCTAssertFalse(isLoading)
                loadingExp.fulfill()
            }.store(in: &subscriptions)
        
        let dismissExp = expectation(description: "Dismiss view")
        sut.$shouldDismiss
            .dropFirst()
            .sink { shouldDismiss in
                XCTAssertTrue(shouldDismiss)
                dismissExp.fulfill()
            }.store(in: &subscriptions)
        
        continuation.yield(.success)
        continuation.finish()
        
        await fulfillment(of: [loadingExp, dismissExp], timeout: 1.5)
    }
    
    private func assertFailedPurchasePlanResultUpdate_shouldHandleRequest(error: AccountPlanErrorEntity) async throws -> UpgradeAccountPlanAlertType? {
        let (stream, continuation) = AsyncStream<Result<Void, AccountPlanErrorEntity>>.makeStream()
        let mockUsecase = MockAccountPlanPurchaseUseCase(purchasePlanResultUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(purchaseUseCase: mockUsecase)
        
        trackTaskCancellation { try await sut.startPurchaseUpdatesMonitoring() }
        
        let isPaymentCancelled = error.errorCode == 2
        let exp = expectation(description: "Present error alert")
        exp.isInverted = isPaymentCancelled
        sut.$isAlertPresented
            .filter { $0 }
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        continuation.yield(.failure(error))
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.isAlertPresented, !isPaymentCancelled)
        
        return sut.alertType
    }
    
    func testStartPurchaseUpdatesMonitoring_purchasePlanResultUpdates_whenFailedAndNotCancelled_shouldHandleRequest() async throws {
        let alertTypeResult = try await assertFailedPurchasePlanResultUpdate_shouldHandleRequest(
            error: .init(errorCode: randomAccountPlanPurchaseErrorCode(excludingCancelError: true), errorMessage: nil)
        )
        
        let newAlertType = try XCTUnwrap(alertTypeResult)
        guard case .purchase(let status) = newAlertType else {
            XCTFail("Alert type mismatched the newly set type - Purchase failed")
            return
        }
        XCTAssertEqual(status, .failed)
    }
    
    func testStartPurchaseUpdatesMonitoring_purchasePlanResultUpdates_whenFailedAndCancelled_shouldHandleRequest() async throws {
        let paymentCancelledErrorCode = 2
        let alertTypeResult = try await assertFailedPurchasePlanResultUpdate_shouldHandleRequest(
            error: .init(errorCode: paymentCancelledErrorCode, errorMessage: nil)
        )
        
        XCTAssertNil(alertTypeResult)
    }
    
    private func assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: RestorePurchaseStateEntity) async throws -> UpgradeAccountPlanAlertType.AlertStatus {
        let (stream, continuation) = AsyncStream<RestorePurchaseStateEntity>.makeStream()
        let mockUsecase = MockAccountPlanPurchaseUseCase(restorePurchaseUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(purchaseUseCase: mockUsecase)
        
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
    
    func testStartPurchaseUpdatesMonitoring_restorePurchaseUpdates_whenSuccessful_shouldShowAlert() async throws {
        let alertStatusResult = try await assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: .success)
        XCTAssertEqual(alertStatusResult, .success)
    }
    
    func testStartPurchaseUpdatesMonitoring_restorePurchaseUpdates_whenIncomplete_shouldShowAlert() async throws {
        let alertStatusResult = try await assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: .incomplete)
        XCTAssertEqual(alertStatusResult, .incomplete)
    }
    
    func testStartPurchaseUpdatesMonitoring_restorePurchaseUpdates_whenFailed_shouldShowAlert() async throws {
        let alertStatusResult = try await assertRestorePurchaseUpdates_shouldShowAlert(restoreUpdate: .failed(.random))
        XCTAssertEqual(alertStatusResult, .failed)
    }

    // MARK: - Event Tracking
    
    func testTrackProIIICardDisplayedEvent_onMultipleCalls_shouldTrackEventOnce() async {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)

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
        let sut = makeSUT(tracker: tracker)
        sut.setSelectedPlan(PlanEntity(type: planType))

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
        purchaseUseCase: AccountPlanPurchaseUseCaseProtocol? = nil,
        planList: [PlanEntity] = [],
        tracker: AnalyticsTracking = MockTracker(),
        accountDetailsResult: Result<AccountDetailsEntity, AccountDetailsErrorEntity> = .failure(.generic),
        isAdsEnabled: Bool = false,
        baseStorage: Int = 20,
        notificationCenter: NotificationCenter = NotificationCenter(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> OnboardingUpgradeAccountViewModel {
        let mockPurchaseUseCase = purchaseUseCase ?? MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let mockAccountUseCase = MockAccountUseCase(accountDetailsResult: accountDetailsResult)
        let router = MockOnboardingUpgradeAccountRouter()
        let sut = OnboardingUpgradeAccountViewModel(
            purchaseUseCase: mockPurchaseUseCase, 
            accountUseCase: mockAccountUseCase,
            tracker: tracker, 
            isAdsEnabled: isAdsEnabled,
            baseStorage: baseStorage,
            viewProPlanAction: {},
            router: router,
            notificationCenter: notificationCenter
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
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
}
