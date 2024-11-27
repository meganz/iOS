@testable import Accounts
import AccountsMock
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

@MainActor
final class CancellationSurveyViewModelTests: XCTestCase {
    // MARK: - Multiple selection
    func testUpdateSelectedReason_whenReasonIsNotOnTheList_shouldAddReasonAndHideReasonError() {
        assertUpdateSelectedReason(
            currentSelectedReasons: [],
            newSelectedReason: randomCustomReason,
            shouldAddSelectedReason: true
        )
    }
    
    func testUpdateSelectedReason_whenReasonIsOnTheList_shouldRemoveReason() {
        let selectedReason = randomCustomReason
        assertUpdateSelectedReason(
            currentSelectedReasons: [selectedReason],
            newSelectedReason: selectedReason,
            shouldAddSelectedReason: false
        )
    }
    
    func testUpdateSelectedReason_whenAddedOtherReason_shouldShowOtherField() {
        let sut = makeSUT()
        sut.selectedReasons = []
        
        sut.updateSelectedReason(customOtherReason)
        
        XCTAssertTrue(sut.showOtherField)
    }
    
    func testUpdateSelectedReason_whenOtherReasonIsOnTheListAndAddedNewReason_shouldShowOtherField() {
        let sut = makeSUT()
        sut.selectedReasons = []
        
        // Add other reason
        sut.updateSelectedReason(customOtherReason)
        
        // Add new reason
        sut.updateSelectedReason(randomCustomReasonExceptOthers)
        
        XCTAssertTrue(sut.showOtherField)
    }
    
    func testIsReasonSelected_whenReasonSelected_shouldReturnTrue() {
        let selectedReason = randomCustomReason
        
        let sut = makeSUT()
        sut.selectedReasons = [selectedReason]
        
        XCTAssertTrue(sut.isReasonSelected(selectedReason))
    }
    
    func testIsReasonSelected_whenReasonNotSelected_shouldReturnFalse() {
        let reasonList = customReasonList
        let sut = makeSUT()
        sut.selectedReasons = Set(reasonList.prefix(2))
        
        XCTAssertFalse(sut.isReasonSelected(reasonList[2]), "Should return false. Reason 3 is not included on selectedReasons.")
    }
    
    // MARK: - Single selection - reason validation
    func testSelectReason_whenIsMultipleSelectionDisabled_shouldSetCorrectReasonAndHideReasonErrorAndKeyboard() {
        let expectedReason = randomCustomReason
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.isOtherFieldFocused = Bool.random()
        sut.surveyFormError = randomSurveyFormError()
        
        sut.updateSelectedReason(expectedReason)
        
        XCTAssertEqual(sut.selectedReason, expectedReason)
        XCTAssertFalse(sut.isOtherFieldFocused)
        XCTAssertEqual(sut.surveyFormError, .none)
    }
    
    func testIsReasonSelected_whenIsMultipleSelectionDisabledAndReasonSelected_shouldReturnTrue() {
        let selectedReason = randomCustomReason
        
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = selectedReason
        
        XCTAssertTrue(sut.isReasonSelected(selectedReason))
    }
    
    func testIsReasonSelected_whenIsMultipleSelectionDisabledAndReasonNotSelected_shouldReturnFalse() {
        let reasonList = customReasonList
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = reasonList[0]
        
        XCTAssertFalse(sut.isReasonSelected(reasonList[1]), "Should return false. Reason 2 is the selected reason.")
    }
    
    // MARK: - Actions
    func testDidTapCancelButton_shouldDismissView() {
        let sut = makeSUT()
        
        sut.didTapCancelButton()
        
        XCTAssertTrue(sut.shouldDismiss)
    }
    
    func testDidTapDontCancelButton_shouldDismissViewAndDismissCancellationFlow() {
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
    
    func testTracker_didTapCancelButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        
        sut.didTapCancelButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyCancelViewButtonEvent()]
        )
    }
    
    func testTracker_didTapDontCancelButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        
        sut.didTapDontCancelButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyDontCancelButtonEvent()]
        )
    }
    
    // MARK: - Multiple selection - Cancel subscription
    
    func testTracker_isMultipleSelectionDisabled_didTapCancelSubscriptionButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker)
        sut.selectedReasons = [randomCustomReason]
        sut.otherReasonText = "This is a test reason"
        
        sut.didTapCancelSubscriptionButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyCancelSubscriptionButtonEvent()]
        )
    }
    
    func testDidTapCancelSubscriptionButton_whenNoSelectedReason_shouldSetSurveyFormErrorToNoSelectedReason() {
        let sut = makeSUT()
        sut.selectedReasons = []
        sut.surveyFormError = .none
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertEqual(sut.surveyFormError, .noSelectedReason)
    }
    
    func testDidTapCancelSubscriptionButton_whenNoSelectedFollowUpReason_shouldSetSurveyFormErrorToNoSelectedFollowUpReason() throws {
        let reasonList = reasonWithFollowUpOptionsList()
        let selectedReason = try XCTUnwrap(reasonList.randomElement())
        
        let sut = makeSUT(
            reasonList: reasonList,
            featureFlagList: [
                .multipleOptionsForCancellationSurvey: false,
                .followUpOptionsForCancellationSurvey: true
            ]
        )
        sut.selectedReason = selectedReason
        sut.selectedFollowUpReasons = []
        sut.surveyFormError = .none
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertEqual(sut.surveyFormError, .noSelectedFollowUpReason(selectedReason))
    }
    
    func testDidTapCancelSubscriptionButton_whenOtherReasonSelected_shouldHandleTextCountCorrectly() {
        let sut = makeSUT()
        sut.selectedReasons = [customOtherReason]
        
        sut.otherReasonText = String(repeating: "a", count: 121)
        sut.didTapCancelSubscriptionButton()
        XCTAssertNil(sut.submitSurveyTask, "The reason has reached the maximum limit of 120 characters. Submission should not proceed.")
        
        sut.otherReasonText = String(repeating: "a", count: 120)
        sut.didTapCancelSubscriptionButton()
        XCTAssertTrue(sut.dismissKeyboard, "The reason is within the 120-character limit. Should dismiss the keyboard and proceed with the submission.")
    }
    
    func testDidTapCancelSubscriptionButton_whenReasonSelectedAndCancellationRequestSuccessForItunesPaymentMethod_shouldShowManageSubscriptions() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: .itunes,
            requestResult: .success,
            shouldShowManageSubscriptions: true,
            isFeatureFlagEnabled: true
        )
    }
    
    func testDidTapCancelSubscriptionButton_whenReasonSelectedAndCancellationRequestSuccessForRandomWebclientPaymentMethod_shouldShowSuccessAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .success,
            shouldShowManageSubscriptions: false,
            isFeatureFlagEnabled: true
        )
    }
    
    func testDidTapCancelSubscriptionButton_whenReasonSelectedAndCancellationRequestFailure_shouldShowFailureAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .failure(.generic),
            shouldShowManageSubscriptions: false,
            shouldShowFailure: true,
            isFeatureFlagEnabled: true
        )
    }
    
    func testDidTapCancelSubscriptionButton_whenReasonSelectedAndCancellationRequestSuccess_shouldShowSuccessAlertWithCorrectExpirationDate() async {
        let expectedExpirationDate = Date().addingTimeInterval(24*60*60)
        let expectation = XCTestExpectation(description: "Success alert should display the correct expiration date")
        
        let mockRouter = MockCancelAccountPlanRouter { expirationDate in
            Task { @MainActor in
                self.assertExpirationDate(expirationDate, matches: expectedExpirationDate, expectation: expectation)
            }
        }
        
        let sut = makeSUT(
            requestResult: .success,
            paymentMethod: randomWebclientPaymentMethod(),
            mockRouter: mockRouter,
            expirationDate: expectedExpirationDate
        )
        
        sut.selectedReasons = [randomCustomReason]
        sut.otherReasonText = "Test reason"
        
        sut.didTapCancelSubscriptionButton()
        await sut.submitSurveyTask?.value
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRouter.showSuccessAlert_calledTimes, 1, "Success alert should be shown exactly once")
    }
    
    // MARK: - Single selection - Cancel subscription
    
    func testTracker_didTapCancelSubscriptionButton_shouldTrackEvent() {
        let mockTracker = MockTracker()
        let sut = makeSUT(mockTracker: mockTracker, featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = randomCustomReason
        sut.otherReasonText = "This is a test reason"
        
        sut.didTapCancelSubscriptionButton()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [SubscriptionCancellationSurveyCancelSubscriptionButtonEvent()]
        )
    }
    
    func testDidTapCancelSubscriptionButton_whenIsMultipleSelectionDisabledAndNoSelectedReason_shouldSetSurveyFormErrorToNoSelectedReason() {
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = nil
        sut.surveyFormError = .none
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertEqual(sut.surveyFormError, .noSelectedReason)
    }
    
    func testDidTapCancelSubscriptionButton_whenIsMultipleSelectionDisabled_otherReasonSelected_reasonTextIsEmpty_shouldSetIsOtherFieldFocusedToTrue() {
        assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(reasonText: "", isFeatureFlagEnabled: false)
    }
    
    func testDidTapCancelSubscriptionButton_whenIsMultipleSelectionDisabled_otherReasonSelected_reasonTextIsLessThanMinLimit10_shouldSetIsOtherFieldFocusedToTrue() {
        assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(reasonText: "Test", isFeatureFlagEnabled: false)
    }
    
    func testDidTapCancelSubscriptionButton_isMultipleSelectionDisabled_otherReasonSelected_shouldHandleTextCountCorrectly() {
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: false])
        sut.selectedReason = customOtherReason
        
        sut.otherReasonText = String(repeating: "a", count: 121)
        sut.didTapCancelSubscriptionButton()
        XCTAssertNil(sut.submitSurveyTask, "The reason has reached the maximum limit of 120 characters. Submission should not proceed.")
        
        sut.otherReasonText = String(repeating: "a", count: 120)
        sut.didTapCancelSubscriptionButton()
        XCTAssertTrue(sut.dismissKeyboard, "The reason is within the 120-character limit. Should dismiss the keyboard and proceed with the submission.")
    }
    
    func testDidTapCancelSubscriptionButton_whenIsMultipleSelectionDisabled_reasonSelectedAndCancellationRequestSuccessForItunesPaymentMethod_shouldShowManageSubscriptions() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: .itunes,
            requestResult: .success,
            shouldShowManageSubscriptions: true,
            isFeatureFlagEnabled: false
        )
    }
    
    func testDidTapCancelSubscriptionButton_whenIsMultipleSelectionDisabled_reasonSelectedAndCancellationRequestSuccessForRandomWebclientPaymentMethod_shouldShowSuccessAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .success,
            shouldShowManageSubscriptions: false,
            isFeatureFlagEnabled: false
        )
    }
    
    func testDidTapCancelSubscriptionButton_whenIsMultipleSelectionDisabled_reasonSelectedAndCancellationRequestFailure_shouldShowFailureAlert() async {
        await assertDidTapCancelSubscriptionButtonWithValidForm(
            paymentMethod: randomWebclientPaymentMethod(),
            requestResult: .failure(.generic),
            shouldShowManageSubscriptions: false,
            shouldShowFailure: true,
            isFeatureFlagEnabled: false
        )
    }
    
    @MainActor func testDidTapCancelSubscriptionButton_whenIsMultipleSelectionDisabled_reasonSelectedAndCancellationRequestSuccess_shouldShowSuccessAlertWithCorrectExpirationDate() async {
        let expectedExpirationDate = Date().addingTimeInterval(24*60*60)
        let expectation = XCTestExpectation(description: "Success alert should display the correct expiration date")
        
        let mockRouter = MockCancelAccountPlanRouter { expirationDate in
            Task { @MainActor in
                self.assertExpirationDate(expirationDate, matches: expectedExpirationDate, expectation: expectation)
            }
        }
        
        let sut = makeSUT(
            requestResult: .success,
            paymentMethod: randomWebclientPaymentMethod(),
            mockRouter: mockRouter,
            expirationDate: expectedExpirationDate,
            featureFlagList: [.multipleOptionsForCancellationSurvey: false]
        )
        
        sut.selectedReason = randomCustomReason
        sut.otherReasonText = "Test reason"
        
        sut.didTapCancelSubscriptionButton()
        await sut.submitSurveyTask?.value
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRouter.showSuccessAlert_calledTimes, 1, "Success alert should be shown exactly once")
    }
    
    // MARK: - Follow-up reasons
    func testUpdateSelectedFollowUpReason_whenOnTheList_shouldKeepItSelected() {
        let selectedFollowUpReason = randomFollowUpReason
        assertUpdateFollowUpReason(
            selectedFollowUpReason: selectedFollowUpReason,
            currentSelectedList: [selectedFollowUpReason],
            expectedSelectedList: [selectedFollowUpReason]
        )
    }
    
    func testUpdateSelectedFollowUpReason_whenNotOnTheList_shouldAddToSelectionList() {
        let selectedFollowUpReason = randomFollowUpReason
        assertUpdateFollowUpReason(
            selectedFollowUpReason: selectedFollowUpReason,
            currentSelectedList: [],
            expectedSelectedList: [selectedFollowUpReason]
        )
    }
    
    func testUpdateFollowUpReason_whenNotOnTheListButSameMainReasonIdExist_shouldReplaceSelection() {
        let randomMainReasonID = randomReasonID
        let selectedFollowUpReason = CancellationSurveyFollowUpReason(id: .a, mainReasonID: randomMainReasonID, title: "Follow up reason one")
        assertUpdateFollowUpReason(
            selectedFollowUpReason: selectedFollowUpReason,
            currentSelectedList: [CancellationSurveyFollowUpReason(id: .b, mainReasonID: randomMainReasonID, title: "Follow up reason two")],
            expectedSelectedList: [selectedFollowUpReason]
        )
    }
    
    func testIsFollowUpReasonSelected_whenSelected_shouldReturnTrue() {
        let selectedFollowUpReason = randomFollowUpReason
        assertIsFollowUpReasonSelected(followUpReason: selectedFollowUpReason, currentSelectedList: [selectedFollowUpReason], expectedResult: true)
    }
    
    func testIsFollowUpReasonSelected_whenNotSelected_shouldReturnTrue() {
        assertIsFollowUpReasonSelected(followUpReason: randomFollowUpReason, currentSelectedList: [], expectedResult: false)
    }
    
    func testFollowUpReasons_whenIsFollowUpFeatureFlagEnabledAndHasFollowUpReason_shouldReturnList() {
        let mainReasonID = randomReasonID
        let followUpReasons = customFollowUpReasons(with: mainReasonID)
        
        assertFollowUpReasons(
            isFeatureFlagEnabled: true,
            followUpReasons: followUpReasons,
            selectedMainReasonID: mainReasonID,
            expectedResult: followUpReasons
        )
    }
    
    func testFollowUpReasons_whenIsFollowUpFeatureFlagEnabledAndHasNoFollowUpReason_shouldReturnNil() {
        assertFollowUpReasons(
            isFeatureFlagEnabled: true,
            followUpReasons: [],
            selectedMainReasonID: randomReasonID,
            expectedResult: nil
        )
    }
    
    func testFollowUpReasons_whenIsFollowUpFeatureFlagDisabledAndHasFollowUpReason_shouldReturnNil() {
        let mainReasonID = randomReasonID
        assertFollowUpReasons(
            isFeatureFlagEnabled: false,
            followUpReasons: customFollowUpReasons(with: mainReasonID),
            selectedMainReasonID: mainReasonID,
            expectedResult: nil
        )
    }
    
    // MARK: - CancelSubscriptionReasonSelectionList
    func testCancelSubscriptionReasonSelectionList_whenSelectedReasonIsNilAndSelectedReasonsIsEmpty_shouldReturnEmptyList() {
        assertCancelSubscriptionReasonSelectionList(selectedReason: nil, selectedReasons: [], expectedResult: [])
    }
    
    func testCancelSubscriptionReasonSelectionList_whenMultipleOptionsIsEnabledAndHasSelectedReasons_shouldReturnList() throws {
        let reasonList = reasonWithFollowUpOptionsList()
        let (selectedReason, mainPositionIndex) = try XCTUnwrap(randomSelectedReason(from: reasonList))
        
        assertCancelSubscriptionReasonSelectionList(
            reasonList: reasonList,
            selectedReasons: [selectedReason],
            isMultipleSelectionEnabled: true,
            expectedResult: [CancelSubscriptionReasonEntity(text: String(selectedReason.id.rawValue), position: mainPositionIndex)]
        )
    }
    
    func testCancelSubscriptionReasonSelectionList_whenMultipleOptionsIsEnabledAndHasNoSelectedReasons_shouldReturnEmptyList() {
        assertCancelSubscriptionReasonSelectionList(
            selectedReasons: [],
            isMultipleSelectionEnabled: true,
            expectedResult: []
        )
    }
    
    func testCancelSubscriptionReasonSelectionList_whenMultipleOptionsIsDisabledAndHasNoSelectedReason_shouldReturnEmptyList() {
        assertCancelSubscriptionReasonSelectionList(
            selectedReason: nil,
            isMultipleSelectionEnabled: false,
            expectedResult: []
        )
    }
    
    func testCancelSubscriptionReasonSelectionList_whenFollowUpOptionIsEnabled_shouldReturnListWithoutTheMainReason() throws {
        let reasonList = reasonWithFollowUpOptionsList()
        let (selectedReason, mainPositionIndex) = try XCTUnwrap(randomSelectedReason(from: reasonList))
        let (randomFollowUpReason, newPositionID) = try XCTUnwrap(randomSelectedFollowUpReason(from: selectedReason.followUpReasons))

        assertCancelSubscriptionReasonSelectionList(
            reasonList: reasonList,
            selectedReason: selectedReason,
            selectedReasons: [selectedReason],
            isMultipleSelectionEnabled: Bool.random(),
            isFollowUpOptionEnabled: true,
            selectedFollowUpReasons: [randomFollowUpReason],
            expectedResult: [
                CancelSubscriptionReasonEntity(
                    text: String(selectedReason.id.rawValue) + "." + randomFollowUpReason.id.rawValue, // ex. 1.a
                    position: String(mainPositionIndex) + "." + newPositionID // Position on the list
                )
            ]
        )
    }
    
    func testCancelSubscriptionReasonSelectionList_whenOtherReasonsSelected_shouldReturnCorrectFormat() {
        let reasonList = customReasonList
        let selectedOtherReason = customOtherReason
        let expectedOtherReasonText = "Test reason"
        
        assertCancelSubscriptionReasonSelectionList(
            reasonList: reasonList,
            selectedReason: selectedOtherReason,
            otherReasonText: expectedOtherReasonText,
            expectedResult: [
                CancelSubscriptionReasonEntity(
                    text: "\(selectedOtherReason.id.rawValue) - \(expectedOtherReasonText)",
                    position: String(reasonList.count)
                )
            ]
        )
    }
    
    // MARK: - Helper
    private func makeSUT(
        reasonList: [CancellationSurveyReason]? = nil,
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
            cancellationSurveyReasonList: reasonList ?? customReasonList,
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
    
    private var customReasonList: [CancellationSurveyReason] {
        [
            CancellationSurveyReason(id: .one, title: "Reason one"),
            CancellationSurveyReason(id: .two, title: "Reason two"),
            CancellationSurveyReason(id: .three, title: "Reason three"),
            CancellationSurveyReason(id: .four, title: "Reason four"),
            customOtherReason
        ]
    }
    
    private func reasonWithFollowUpOptionsList() -> [CancellationSurveyReason] {
        [
            CancellationSurveyReason(id: .one, title: "Reason one", followUpReasons: customFollowUpReasons(with: .one)),
            CancellationSurveyReason(id: .two, title: "Reason two", followUpReasons: customFollowUpReasons(with: .two)),
            CancellationSurveyReason(id: .three, title: "Reason three", followUpReasons: customFollowUpReasons(with: .three))
        ]
    }
    
    private func customFollowUpReasons(with mainReasonID: CancellationSurveyReason.ID) -> [CancellationSurveyFollowUpReason] {
        [
           CancellationSurveyFollowUpReason(id: .a, mainReasonID: mainReasonID, title: "FollowUp one"),
           CancellationSurveyFollowUpReason(id: .b, mainReasonID: mainReasonID, title: "FollowUp two"),
           CancellationSurveyFollowUpReason(id: .c, mainReasonID: mainReasonID, title: "FollowUp three")
       ]
    }
    
    private let customOtherReason: CancellationSurveyReason = CancellationSurveyReason(id: .eight, title: "Reason eight")
    
    private var randomCustomReason: CancellationSurveyReason {
        customReasonList.randomElement() ?? CancellationSurveyReason(id: .one, title: "Reason one")
    }
    
    private var randomCustomReasonExceptOthers: CancellationSurveyReason {
        customReasonList.filter { !$0.isOtherReason }.randomElement() ?? CancellationSurveyReason(id: .one, title: "Reason one")
    }
    
    private var randomFollowUpReason: CancellationSurveyFollowUpReason {
        CancellationSurveyFollowUpReason(
            id: CancellationSurveyFollowUpReason.ID.allCases.randomElement() ?? .a,
            mainReasonID: randomReasonID,
            title: "Follow up reason"
        )
    }
    
    private var randomReasonID: CancellationSurveyReason.ID {
        .allCases.randomElement() ?? .one
    }
    
    private func randomWebclientPaymentMethod() -> PaymentMethodEntity {
        PaymentMethodEntity.allCases
            .filter { $0 != .itunes && $0 != .googleWallet }
            .randomElement() ?? .stripe
    }
    
    private func randomSelectedReason(
        from list: [CancellationSurveyReason]
    ) -> (
        reason: CancellationSurveyReason,
        positionIndex: String
    )? {
        guard let randomReason = list.randomElement(),
              let index = list.firstIndex(of: randomReason) else {
            return nil
            
        }
        return (reason: randomReason, positionIndex: String(index + 1))
    }
    
    private func randomSelectedFollowUpReason(
        from list: [CancellationSurveyFollowUpReason]
    ) -> (
        reason: CancellationSurveyFollowUpReason,
        positionID: String
    )? {
        guard let randomReason = list.randomElement(),
           let index = list.firstIndex(of: randomReason) else {
            return nil
        }
        
        let ids = CancellationSurveyFollowUpReason.ID.allCases.prefix(list.count)
        let newID = ids[index]
        return (reason: randomReason, positionID: newID.rawValue)
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
    
    private func randomSurveyFormError() -> CancellationSurveyViewModel.SurveyFormError {
        var errors: [CancellationSurveyViewModel.SurveyFormError] = [.noSelectedReason, .none]
        if let firstError = CancellationSurveyReason.makeList().first {
            errors.append(.noSelectedFollowUpReason(firstError))
        }
        return errors.randomElement() ?? .noSelectedReason
    }
    
    private func assertUpdateSelectedReason(
        currentSelectedReasons: Set<CancellationSurveyReason>,
        newSelectedReason: CancellationSurveyReason,
        shouldAddSelectedReason: Bool
    ) {
        let sut = makeSUT()
        let expectedIsOtherFieldFocused = Bool.random()
        sut.selectedReasons = currentSelectedReasons
        sut.isOtherFieldFocused = expectedIsOtherFieldFocused
        sut.surveyFormError = randomSurveyFormError()
        
        sut.updateSelectedReason(newSelectedReason)
        
        XCTAssertEqual(sut.selectedReasons.contains(newSelectedReason), shouldAddSelectedReason)
        XCTAssertEqual(sut.isOtherFieldFocused, expectedIsOtherFieldFocused)
        XCTAssertEqual(sut.surveyFormError, .none)
    }
    
    private func assertDidTapCancelSubscriptionButtonWithMinOrEmptyField(
        reasonText: String,
        isFeatureFlagEnabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(featureFlagList: [.multipleOptionsForCancellationSurvey: isFeatureFlagEnabled])
        
        if isFeatureFlagEnabled {
            sut.selectedReasons = [customOtherReason]
        } else {
            sut.selectedReason = customOtherReason
        }
        
        sut.otherReasonText = reasonText
        
        sut.didTapCancelSubscriptionButton()
        
        XCTAssertTrue(sut.showMinLimitOrEmptyOtherFieldError, file: file, line: line)
        XCTAssertNil(sut.submitSurveyTask, file: file, line: line)
    }
    
    private func assertDidTapCancelSubscriptionButtonWithValidForm(
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
            sut.selectedReasons = [customOtherReason]
        } else {
            sut.selectedReason = customOtherReason
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
    
    private func assertUpdateFollowUpReason(
        selectedFollowUpReason: CancellationSurveyFollowUpReason,
        currentSelectedList: Set<CancellationSurveyFollowUpReason>,
        expectedSelectedList: Set<CancellationSurveyFollowUpReason>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT()
        sut.selectedFollowUpReasons = currentSelectedList
        
        sut.updateSelectedFollowUpReason(selectedFollowUpReason)
        
        XCTAssertEqual(sut.selectedFollowUpReasons, expectedSelectedList, file: file, line: line)
        XCTAssertEqual(sut.surveyFormError, .none, file: file, line: line)
    }
    
    func assertIsFollowUpReasonSelected(
        followUpReason: CancellationSurveyFollowUpReason,
        currentSelectedList: Set<CancellationSurveyFollowUpReason>,
        expectedResult: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT()
        sut.selectedFollowUpReasons = currentSelectedList
        
        XCTAssertEqual(sut.isFollowUpReasonSelected(followUpReason), expectedResult, file: file, line: line)
    }
    
    private func assertFollowUpReasons(
        isFeatureFlagEnabled: Bool,
        followUpReasons: [CancellationSurveyFollowUpReason],
        selectedMainReasonID: CancellationSurveyReason.ID,
        expectedResult: [CancellationSurveyFollowUpReason]?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(featureFlagList: [.followUpOptionsForCancellationSurvey: isFeatureFlagEnabled])
        let reason = CancellationSurveyReason(id: selectedMainReasonID, title: "Reason", followUpReasons: followUpReasons)
        
        XCTAssertEqual(sut.followUpReasons(reason), expectedResult, file: file, line: line)
    }
    
    private func assertCancelSubscriptionReasonSelectionList(
        reasonList: [CancellationSurveyReason]? = nil,
        selectedReason: CancellationSurveyReason? = nil,
        selectedReasons: Set<CancellationSurveyReason> = [],
        isMultipleSelectionEnabled: Bool = false,
        isFollowUpOptionEnabled: Bool = false,
        selectedFollowUpReasons: Set<CancellationSurveyFollowUpReason> = [],
        otherReasonText: String = "",
        expectedResult: [CancelSubscriptionReasonEntity]
    ) {
        let sut = makeSUT(
            reasonList: reasonList,
            featureFlagList: [
                .multipleOptionsForCancellationSurvey: isMultipleSelectionEnabled,
                .followUpOptionsForCancellationSurvey: isFollowUpOptionEnabled
            ]
        )
        
        sut.selectedReason = selectedReason // Used if multipleOptionsForCancellationSurvey is disabled
        sut.selectedReasons = selectedReasons // Used if multipleOptionsForCancellationSurvey is enabled
        sut.selectedFollowUpReasons = selectedFollowUpReasons
        sut.otherReasonText = otherReasonText
        
        let resultReasonList = sut.cancelSubscriptionReasonSelectionList()

        XCTAssertEqual(resultReasonList, expectedResult)
    }
}
