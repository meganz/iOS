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
    
    @MainActor func testSelectReason_shouldSetCorrectReason_andShouldHideReasonErrorAndKeyboard() {
        let expectedReason = randomReason
        let sut = makeSUT()
        sut.isOtherFieldFocused = Bool.random()
        sut.showNoReasonSelectedError = Bool.random()
        
        sut.selectReason(expectedReason)
        
        XCTAssertEqual(sut.selectedReason, expectedReason)
        XCTAssertFalse(sut.isOtherFieldFocused)
        XCTAssertFalse(sut.showNoReasonSelectedError)
    }
    
    func testFormattedReasonString_forOtherReason_shouldReturnCorrectFormat() {
        let expectedText = "This is a test reason"
        
        let sut = makeSUT()
        sut.selectedReason = CancellationSurveyReason.otherReason
        sut.otherReasonText = expectedText
        
        XCTAssertEqual(sut.formattedReasonString, expectedText)
    }
    
    func testFormattedReasonString_anyReasonExceptOtherReason_shouldReturnCorrectFormat() {
        let randomReason = CancellationSurveyReason.allCases.filter { !$0.isOtherReason }.randomElement() ?? .one
        let expectedText = "\(randomReason.id) - \(randomReason.title)"
        
        let sut = makeSUT()
        sut.selectedReason = randomReason
        
        XCTAssertEqual(sut.formattedReasonString, expectedText)
    }
    
    func testIsReasonSelected_reasonSelected_shouldReturnTrue() {
        let selectedReason = randomReason
        
        let sut = makeSUT()
        sut.selectedReason = selectedReason
        
        XCTAssertTrue(sut.isReasonSelected(selectedReason))
    }
    
    func testIsReasonSelected_reasonNotSelected_shouldReturnFalse() {
        let selectedReason: CancellationSurveyReason = [.one, .two, .three].randomElement() ?? .one
        let newReason: CancellationSurveyReason = [.four, .five, .six].randomElement() ?? .four
        
        let sut = makeSUT()
        sut.selectedReason = selectedReason
        
        XCTAssertFalse(sut.isReasonSelected(newReason))
    }
    
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
    
    func testTracker_viewOnAppear_shouldTrackEvent() {
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
    
    @MainActor func testTracker_didTapCancelSubscriptionButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        sut.selectedReason = randomReason
        sut.otherReasonText = "This is a test reason"
        
        sut.didTapCancelSubscriptionButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyCancelSubscriptionButtonEvent()]
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_noSelectedReason_shouldSetShowNoReasonSelectedErrorToTrue() {
        let sut = makeSUT()
        sut.selectedReason = nil
        sut.showNoReasonSelectedError = false
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.showNoReasonSelectedError)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_otherReasonSelected_reasonTextIsEmpty_shouldSetIsOtherFieldFocusedToTrue() {
        assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(reasonText: "")
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_otherReasonSelected_reasonTextIsLessThanMinLimit10_shouldSetIsOtherFieldFocusedToTrue() {
        assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(reasonText: "Test")
    }
    
    @MainActor private func assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(
        reasonText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT()
        sut.selectedReason = CancellationSurveyReason.otherReason
        sut.otherReasonText = reasonText
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.showMinLimitOrEmptyOtherFieldError, file: file, line: line)
        XCTAssertNil(sut.submitSurveyTask, file: file, line: line)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_otherReasonSelected_shouldHandleTextCountCorrectly() {
        let sut = makeSUT()
        sut.selectedReason = CancellationSurveyReason.otherReason
        
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
            shouldShowManageSubscriptions: true
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelectedAndCancellationRequestSuccessForRandomWebclientPaymentMethod_shouldShowSuccessAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .success,
            shouldShowManageSubscriptions: false
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelectedAndCancellationRequestFailure_shouldShowFailureAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .failure(.generic),
            shouldShowManageSubscriptions: false,
            shouldShowFailure: true
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let mockRouter = MockCancelAccountPlanRouter()
        let sut = makeSUT(
            requestResult: requestResult,
            paymentMethod: paymentMethod,
            mockRouter: mockRouter
        )
        sut.selectedReason = randomReason
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
    private func makeSUT(
        currentSubscription: AccountSubscriptionEntity = AccountSubscriptionEntity(),
        requestResult: Result<Void, AccountErrorEntity> = .failure(.generic),
        paymentMethod: PaymentMethodEntity = .none,
        mockRouter: MockCancelAccountPlanRouter = MockCancelAccountPlanRouter(),
        mockTracker: some AnalyticsTracking = MockTracker(),
        expirationDate: Date = Date(),
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
            tracker: mockTracker
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private var randomReason: CancellationSurveyReason {
        CancellationSurveyReason.allCases.randomElement() ?? .one
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
