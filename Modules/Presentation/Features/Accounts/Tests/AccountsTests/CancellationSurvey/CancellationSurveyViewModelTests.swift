@testable import Accounts
import AccountsMock
import Combine
import MEGADomain
import MEGADomainMock
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
    
    @MainActor func testDidTapCancelSubscriptionButton_noSelectedReason_shouldSetShowNoReasonSelectedErrorToTrue() {
        let sut = makeSUT()
        sut.selectedReason = nil
        sut.showNoReasonSelectedError = false
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.showNoReasonSelectedError)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_otherReasonSelected_reasonTextIsEmpty_shouldSetIsOtherFieldFocusedToTrue() {
        let sut = makeSUT()
        sut.selectedReason = CancellationSurveyReason.otherReason
        sut.otherReasonText = ""
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.isOtherFieldFocused)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelected_cancellationRequesSuccess_shouldShowManageSubscription() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(requestResult: .success)
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_reasonSelected_cancellationRequesFailed_shouldStillShowManageSubscription() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(requestResult: .failure(.generic))
    }
    
    @MainActor private func assertDidTapCancelSubscriptionButtonWithValidForm(
        requestResult: Result<Void, AccountErrorEntity>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let mockRouter = MockCancelAccountPlanRouter()
        let sut = makeSUT(requestResult: requestResult, mockRouter: mockRouter)
        sut.selectedReason = randomReason
        sut.otherReasonText = "This is a test reason"
        
        sut.didTapCancelSubscriptionButton()
        
        await sut.submitReasonTask?.value
        XCTAssertFalse(sut.isOtherFieldFocused, file: file, line: line)
        XCTAssertEqual(mockRouter.showAppleManageSubscriptions_calledTimes, 1, file: file, line: line)
    }
    
    // MARK: - Helper
    private func makeSUT(
        currentSubscription: AccountSubscriptionEntity = AccountSubscriptionEntity(),
        requestResult: Result<Void, AccountErrorEntity> = .failure(.generic),
        mockRouter: MockCancelAccountPlanRouter = MockCancelAccountPlanRouter(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CancellationSurveyViewModel {
        let subscriptionsUsecase = MockSubscriptionsUsecase(requestResult: requestResult)
        let sut = CancellationSurveyViewModel(
            subscription: currentSubscription,
            subscriptionsUsecase: subscriptionsUsecase,
            cancelAccountPlanRouter: mockRouter
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private var randomReason: CancellationSurveyReason {
        CancellationSurveyReason.allCases.randomElement() ?? .one
    }
}
