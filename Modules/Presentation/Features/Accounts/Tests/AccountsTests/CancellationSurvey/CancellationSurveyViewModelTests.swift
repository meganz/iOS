@testable import Accounts
import AccountsMock
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class CancellationSurveyViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()

    @MainActor func testSetupRandomizedReasonList_cancellationSurveyReasonListShouldNotBeEmpty() {
        let reasonList = CancellationSurveyReason.allCases
        let sut = makeSUT()
        
        sut.setupRandomizedReasonList()
        
        XCTAssertEqual(sut.cancellationSurveyReasonList.count, reasonList.count)
    }
    
    // MARK: - Multiple selection
    @MainActor func testUpdateSelectedReason_whenReasonIsNotOnTheList_shouldAddReasonAndHideReasonError() {
        assertUpdateSelectedReason(
            currentSelectedReasons: [],
            newSelectedReason: randomReason,
            shouldAddSelectedReason: true
        )
    }
    
    @MainActor func testUpdateSelectedReason_whenReasonIsOnTheList_shouldRemoveReason() {
        let selectedReason = randomReason
        assertUpdateSelectedReason(
            currentSelectedReasons: [selectedReason],
            newSelectedReason: selectedReason,
            shouldAddSelectedReason: false
        )
    }
    
    @MainActor private func assertUpdateSelectedReason(
        currentSelectedReasons: Set<CancellationSurveyReason>,
        newSelectedReason: CancellationSurveyReason,
        shouldAddSelectedReason: Bool
    ) {
        let sut = makeSUT()
        let expectedIsOtherFieldFocused = Bool.random()
        sut.selectedReasons = currentSelectedReasons
        sut.isOtherFieldFocused = expectedIsOtherFieldFocused
        sut.showNoReasonSelectedError = Bool.random()
        
        sut.updateSelectedReason(newSelectedReason)
        
        XCTAssertEqual(sut.selectedReasons.contains(newSelectedReason), shouldAddSelectedReason)
        XCTAssertEqual(sut.isOtherFieldFocused, expectedIsOtherFieldFocused)
        XCTAssertFalse(sut.showNoReasonSelectedError)
    }
    
    @MainActor func testUpdateSelectedReason_whenAddedOtherReason_shouldShowOtherField() {
        let sut = makeSUT()
        sut.selectedReasons = []
        
        sut.updateSelectedReason(CancellationSurveyReason.otherReason)
        
        XCTAssertTrue(sut.showOtherField)
    }
    
    @MainActor func testUpdateSelectedReason_whenOtherReasonIsOnTheListAndAddedNewReason_shouldShowOtherField() {
        let sut = makeSUT()
        sut.selectedReasons = []
        
        // Add other reason
        sut.updateSelectedReason(CancellationSurveyReason.otherReason)
        
        // Add new reason
        sut.updateSelectedReason(randomReasonExceptOthers)
        
        XCTAssertTrue(sut.showOtherField)
    }
    
    @MainActor func testIsReasonSelected_whenReasonSelected_shouldReturnTrue() {
        let selectedReason = randomReason
        
        let sut = makeSUT()
        sut.selectedReasons = [selectedReason]
        
        XCTAssertTrue(sut.isReasonSelected(selectedReason))
    }
    
    @MainActor func testIsReasonSelected_whenReasonNotSelected_shouldReturnFalse() {
        let newReasonNotOnList: CancellationSurveyReason = [.four, .five, .six].randomElement() ?? .four
        
        let sut = makeSUT()
        sut.selectedReasons = [.one, .two, .three]
        
        XCTAssertFalse(sut.isReasonSelected(newReasonNotOnList))
    }
    
    // MARK: - Single selection - reason validation
    @MainActor func testSelectReason_isMultipleSelectionDisabled_shouldSetCorrectReasonAndHideReasonErrorAndKeyboard() {
        let expectedReason = randomReason
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.isOtherFieldFocused = Bool.random()
        sut.showNoReasonSelectedError = Bool.random()
        
        sut.updateSelectedReason(expectedReason)
        
        XCTAssertEqual(sut.selectedReason, expectedReason)
        XCTAssertFalse(sut.isOtherFieldFocused)
        XCTAssertFalse(sut.showNoReasonSelectedError)
    }
    
    @MainActor func testFormattedReasonString_isMultipleSelectionDisabled_forOtherReason_shouldReturnCorrectFormat() {
        let expectedText = "This is a test reason"
        
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = CancellationSurveyReason.otherReason
        sut.otherReasonText = expectedText
        
        XCTAssertEqual(sut.formattedReasonString, expectedText)
    }
    
    @MainActor func testFormattedReasonString_isMultipleSelectionDisabled_anyReasonExceptOtherReason_shouldReturnCorrectFormat() {
        let randomReason = randomReasonExceptOthers
        let expectedText = "\(randomReason.id) - \(randomReason.title)"
        
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = randomReason
        
        XCTAssertEqual(sut.formattedReasonString, expectedText)
    }
    
    @MainActor func testIsReasonSelected_isMultipleSelectionDisabled_whenReasonSelected_shouldReturnTrue() {
        let selectedReason = randomReason
        
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = selectedReason
        
        XCTAssertTrue(sut.isReasonSelected(selectedReason))
    }
    
    @MainActor func testIsReasonSelected_isMultipleSelectionDisabled_whenReasonNotSelected_shouldReturnFalse() {
        let selectedReason: CancellationSurveyReason = [.one, .two, .three].randomElement() ?? .one
        let newReason: CancellationSurveyReason = [.four, .five, .six].randomElement() ?? .four
        
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = selectedReason
        
        XCTAssertFalse(sut.isReasonSelected(newReason))
    }
    
    // MARK: - Actions
    @MainActor func testDidTapCancelButton_shouldDismissView() {
        let sut = makeSUT()
        
        sut.didTapCancelButton()
        
        XCTAssertTrue(sut.shouldDismiss)
    }
    
    @MainActor func testDidTapDontCancelButton_shouldDismissViewAndDismissCancellationFlow() {
        let mockRouter = MockCancelAccountPlanRouter()
        let sut = makeSUT(mockRouter: mockRouter)
        
        sut.didTapDontCancelButton()
        
        XCTAssertTrue(sut.shouldDismiss)
        XCTAssertEqual(mockRouter.dismissCancellationFlow_calledTimes, 1)
    }
    
    @MainActor func testTracker_viewOnAppear_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        
        sut.trackViewOnAppear()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyScreenEvent()]
        )
    }
    
    @MainActor func testTracker_didTapCancelButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        
        sut.didTapCancelButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyCancelViewButtonEvent()]
        )
    }
    
    @MainActor func testTracker_didTapDontCancelButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        
        sut.didTapDontCancelButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyDontCancelButtonEvent()]
        )
    }
    
    // MARK: - Multiple selection - Cancel subscription
    
    @MainActor func testTracker_isMultipleSelectionDisabled_didTapCancelSubscriptionButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        sut.selectedReasons = [randomReason]
        sut.otherReasonText = "This is a test reason"
        
        sut.didTapCancelSubscriptionButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyCancelSubscriptionButtonEvent()]
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_noSelectedReason_shouldSetShowNoReasonSelectedErrorToTrue() {
        let sut = makeSUT()
        sut.selectedReasons = []
        sut.showNoReasonSelectedError = false
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.showNoReasonSelectedError)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_otherReasonSelected_shouldHandleTextCountCorrectly() {
        let sut = makeSUT()
        sut.selectedReasons = [CancellationSurveyReason.otherReason]
        
        sut.otherReasonText = String(repeating: "a", count: 121)
        sut.didTapCancelSubscriptionButton()
        XCTAssertNil(sut.submitSurveyTask, "The reason has reached the maximum limit of 120 characters. Submission should not proceed.")
        
        sut.otherReasonText = String(repeating: "a", count: 120)
        sut.didTapCancelSubscriptionButton()
        XCTAssertTrue(sut.dismissKeyboard, "The reason is within the 120-character limit. Should dismiss the keyboard and proceed with the submission.")
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelectedAndCancellationRequestSuccessForItunesPaymentMethod_shouldShowManageSubscriptions() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: .itunes,
            requestResult: .success,
            shouldShowManageSubscriptions: true,
            isFeatureFlagEnabled: true
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelectedAndCancellationRequestSuccessForRandomWebclientPaymentMethod_shouldShowSuccessAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .success,
            shouldShowManageSubscriptions: false,
            isFeatureFlagEnabled: true
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelectedAndCancellationRequestFailure_shouldShowFailureAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .failure(.generic),
            shouldShowManageSubscriptions: false,
            shouldShowFailure: true,
            isFeatureFlagEnabled: true
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelectedAndCancellationRequestSuccess_shouldShowSuccessAlertWithCorrectExpirationDate() async {
        let expectedExpirationDate = Date().addingTimeInterval(24*60*60)
        let expectation = XCTestExpectation(description: "Success alert should display the correct expiration date")
        
        let mockRouter = MockCancelAccountPlanRouter { expirationDate in
            self.assertExpirationDate(expirationDate, matches: expectedExpirationDate, expectation: expectation)
        }
        
        let sut = makeSUT(
            requestResult: .success,
            paymentMethod: randomWebclientPaymentMethod(),
            mockRouter: mockRouter,
            expirationDate: expectedExpirationDate
        )
        
        sut.selectedReasons = [randomReason]
        sut.otherReasonText = "Test reason"
        
        sut.didTapCancelSubscriptionButton()
        await sut.submitSurveyTask?.value
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRouter.showSuccessAlert_calledTimes, 1, "Success alert should be shown exactly once")
    }
    
    // MARK: - Single selection - Cancel subscription
    
    @MainActor func testTracker_didTapCancelSubscriptionButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker, featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = randomReason
        sut.otherReasonText = "This is a test reason"
        
        sut.didTapCancelSubscriptionButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyCancelSubscriptionButtonEvent()]
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_noSelectedReason_shouldSetShowNoReasonSelectedErrorToTrue() {
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = nil
        sut.showNoReasonSelectedError = false
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.showNoReasonSelectedError)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_otherReasonSelected_reasonTextIsEmpty_shouldSetIsOtherFieldFocusedToTrue() {
        assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(reasonText: "", isFeatureFlagEnabled: false)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_otherReasonSelected_reasonTextIsLessThanMinLimit10_shouldSetIsOtherFieldFocusedToTrue() {
        assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(reasonText: "Test", isFeatureFlagEnabled: false)
    }
    
    @MainActor private func assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(
        reasonText: String,
        isFeatureFlagEnabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: isFeatureFlagEnabled])
        
        if isFeatureFlagEnabled {
            sut.selectedReasons = [CancellationSurveyReason.otherReason]
        } else {
            sut.selectedReason = CancellationSurveyReason.otherReason
        }
        
        sut.otherReasonText = reasonText
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.showMinLimitOrEmptyOtherFieldError, file: file, line: line)
        XCTAssertNil(sut.submitSurveyTask, file: file, line: line)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_otherReasonSelected_shouldHandleTextCountCorrectly() {
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = CancellationSurveyReason.otherReason
        
        sut.otherReasonText = String(repeating: "a", count: 121)
        sut.didTapCancelSubscriptionButton()
        XCTAssertNil(sut.submitSurveyTask, "The reason has reached the maximum limit of 120 characters. Submission should not proceed.")
        
        sut.otherReasonText = String(repeating: "a", count: 120)
        sut.didTapCancelSubscriptionButton()
        XCTAssertTrue(sut.dismissKeyboard, "The reason is within the 120-character limit. Should dismiss the keyboard and proceed with the submission.")
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_reasonSelectedAndCancellationRequestSuccessForItunesPaymentMethod_shouldShowManageSubscriptions() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: .itunes,
            requestResult: .success,
            shouldShowManageSubscriptions: true,
            isFeatureFlagEnabled: false
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_reasonSelectedAndCancellationRequestSuccessForRandomWebclientPaymentMethod_shouldShowSuccessAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .success,
            shouldShowManageSubscriptions: false,
            isFeatureFlagEnabled: false
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_reasonSelectedAndCancellationRequestFailure_shouldShowFailureAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .failure(.generic),
            shouldShowManageSubscriptions: false,
            shouldShowFailure: true,
            isFeatureFlagEnabled: false
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_reasonSelectedAndCancellationRequestSuccess_shouldShowSuccessAlertWithCorrectExpirationDate() async {
        let expectedExpirationDate = Date().addingTimeInterval(24*60*60)
        let expectation = XCTestExpectation(description: "Success alert should display the correct expiration date")
        
        let mockRouter = MockCancelAccountPlanRouter { expirationDate in
            self.assertExpirationDate(expirationDate, matches: expectedExpirationDate, expectation: expectation)
        }
        
        let sut = makeSUT(
            requestResult: .success,
            paymentMethod: randomWebclientPaymentMethod(),
            mockRouter: mockRouter,
            expirationDate: expectedExpirationDate,
            featureFlagList: [.multipleOptionsForCancellationSurvey: false]
        )
        
        sut.selectedReason = randomReason
        sut.otherReasonText = "Test reason"
        
        sut.didTapCancelSubscriptionButton()
        await sut.submitSurveyTask?.value
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRouter.showSuccessAlert_calledTimes, 1, "Success alert should be shown exactly once")
    }
    
    @MainActor private func assertDidTapCancelSubscriptionButtonWithValidForm(
        paymentMethod: PaymentMethodEntity,
        requestResult: Result<Void, AccountErrorEntity>,
        shouldShowManageSubscriptions: Bool,
        shouldShowFailure: Bool = false,
        isFeatureFlagEnabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let mockRouter = MockCancelAccountPlanRouter()
        let sut = makeSUT(
            requestResult: requestResult,
            paymentMethod: paymentMethod,
            mockRouter: mockRouter,
            featureFlagList: [.multipleOptionsForCancellationSurvey: isFeatureFlagEnabled]
        )
        if isFeatureFlagEnabled {
            sut.selectedReasons = [CancellationSurveyReason.otherReason]
        } else {
            sut.selectedReason = CancellationSurveyReason.otherReason
        }
        sut.otherReasonText = "Test reason"
        
        sut.didTapCancelSubscriptionButton()
        await sut.submitSurveyTask?.value
        
        if shouldShowManageSubscriptions {
            XCTAssertEqual(mockRouter.showAppleManageSubscriptions_calledTimes, 1, file: file, line: line)
        } else {
            if shouldShowFailure {
                XCTAssertEqual(mockRouter.showFailureAlert_calledTimes, 1, file: file, line: line)
            } else {
                XCTAssertEqual(mockRouter.showSuccessAlert_calledTimes, 1, file: file, line: line)
            }
        }
    }
    
    // MARK: - Helper
    @MainActor private func makeSUT(
        currentSubscription: AccountSubscriptionEntity = AccountSubscriptionEntity(),
        requestResult: Result<Void, AccountErrorEntity> = .failure(.generic),
        paymentMethod: PaymentMethodEntity = .none,
        mockRouter: MockCancelAccountPlanRouter = MockCancelAccountPlanRouter(),
        mockTracker: some AnalyticsTracking = MockTracker(),
        expirationDate: Date = Date(),
        featureFlagList: [FeatureFlagKey: Bool] = [.multipleOptionsForCancellationSurvey: true],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CancellationSurveyViewModel {
        let subscription = AccountSubscriptionEntity(paymentMethodId: paymentMethod)
        let subscriptionsUseCase = MockSubscriptionsUseCase(requestResult: requestResult)
        let accountUseCase = MockAccountUseCase(currentProPlan: AccountPlanEntity(expirationTime: Int64(expirationDate.timeIntervalSince1970)))
        let sut = CancellationSurveyViewModel(
            subscription: subscription,
            subscriptionsUseCase: subscriptionsUseCase,
            accountUseCase: accountUseCase,
            cancelAccountPlanRouter: mockRouter,
            tracker: mockTracker,
            featureFlagProvider: MockFeatureFlagProvider(list: featureFlagList)
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private var randomReason: CancellationSurveyReason {
        CancellationSurveyReason.allCases.randomElement() ?? .one
    }
    
    private var randomReasonExceptOthers: CancellationSurveyReason {
        CancellationSurveyReason.allCases.filter { !$0.isOtherReason }.randomElement() ?? .one
    }
    
    private func randomWebclientPaymentMethod() -> PaymentMethodEntity {
        PaymentMethodEntity.allCases
            .filter { $0 != .itunes && $0 != .googleWallet }
            .randomElement() ?? .stripe
    }
    
    private func dateComponents(from date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: date)
    }
    
    private func assertExpirationDate(_ expirationDate: Date, matches expectedDate: Date, expectation: XCTestExpectation) {
        let actualDateComponents = dateComponents(from: expirationDate)
        let expectedDateComponents = dateComponents(from: expectedDate)
        XCTAssertEqual(actualDateComponents, expectedDateComponents, "Success alert should display the correct expiration date without considering time.")
        expectation.fulfill()
    }
}
