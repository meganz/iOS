@testable import Accounts
import AccountsMock
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class CancelAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    let features = [
        FeatureDetails(
            type: .storage,
            title: "Storage",
            freeText: "20GB",
            proText: "100GB"
        )
    ]

    func testDismiss_shouldTrackAnalyticsEvent() {
        performAnalyticsTest(action: { sut in
            sut.dismiss()
        }, expectedEvent: CancelSubscriptionKeepPlanButtonPressedEvent())
    }
    
    func testDismiss_shouldDismissCancellationFlow() {
        let (sut, router) = makeSUT()
        
        sut.dismiss()

        XCTAssertEqual(router.dismissCancellationFlow_calledTimes, 1, "Expected dismissCancellationFlow to be called on router")
    }
    
    @MainActor func testDidTapContinueCancellation_subscriptionPaymentMethodIsItunes_surveyFeatureFlagIsDisabled_shouldShowAppleManageSubscriptions() async {
        let (sut, router) = makeSUT(
            currentSubscription: AccountSubscriptionEntity(paymentMethodId: .itunes),
            featureFlagProvider: MockFeatureFlagProvider(list: [.subscriptionCancellationSurvey: false])
        )
        
        sut.didTapContinueCancellation()
        
        XCTAssertEqual(router.showAppleManageSubscriptions_calledTimes, 1)
        XCTAssertFalse(sut.showCancellationSurvey)
        XCTAssertFalse(sut.showCancellationSteps)
    }
    
    func testDidTapContinueCancellation_subscriptionPaymentMethodIsNotItunes_shouldShowCancellationSteps() async {
        let paymentMethods = PaymentMethodEntity.allCases.filter { $0 != .itunes }
        let randomPaymentMethod = paymentMethods.randomElement() ?? .stripe
        let (sut, _) = makeSUT(currentSubscription: AccountSubscriptionEntity(paymentMethodId: randomPaymentMethod))
  
        await assertDidTapContinueCancellation(
            sut: sut,
            publisher: sut.$showCancellationSteps,
            expectedVisibility: true
        )
        XCTAssertFalse(sut.showCancellationSurvey)
    }
    
    func testDidTapContinueCancellation_subscriptionPaymentMethodIsItunes_shouldShowCancellationSurvey() async {
        let (sut, _) = makeSUT(currentSubscription: AccountSubscriptionEntity(paymentMethodId: .itunes))
        
        await assertDidTapContinueCancellation(
            sut: sut,
            publisher: sut.$showCancellationSurvey,
            expectedVisibility: true
        )
        XCTAssertFalse(sut.showCancellationSteps)
    }
    
    private func assertDidTapContinueCancellation(
        sut: CancelAccountPlanViewModel,
        publisher: Published<Bool>.Publisher,
        expectedVisibility: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let exp = expectation(description: "Sheet visibility expectation")
        publisher
            .dropFirst()
            .sink(receiveValue: { shouldShow in
                XCTAssertEqual(shouldShow, expectedVisibility, file: file, line: line)
                exp.fulfill()
            })
            .store(in: &subscriptions)
        
        await sut.didTapContinueCancellation()
        await fulfillment(of: [exp], timeout: 0.5)
    }
    
    func testDidTapContinueCancellation_shouldTrackAnalyticsEvent() async {
        let mockTracker = MockTracker()
        let (sut, _) = makeSUT(tracker: mockTracker)
        
        await sut.didTapContinueCancellation()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [
                CancelSubscriptionContinueCancellationButtonPressedEvent()
            ]
        )
    }
    
    func testInit_shouldSetProperties() async {
        let expectedName = "Pro Plan"
        let expectedStorage = "400 GB"
        let (sut, _) = makeSUT(
            currentPlanName: expectedName,
            currentPlanStorageUsed: expectedStorage,
            features: features
        )
        
        await sut.setupFeatureList()
        
        XCTAssertEqual(sut.currentPlanName, expectedName, "Expected currentPlanName to be '\(expectedName)'")
        XCTAssertEqual(sut.currentPlanStorageUsed, expectedStorage, "Expected currentPlanStorageUsed to be '\(expectedStorage)'")
        XCTAssertEqual(sut.features.count, features.count, "Expected features count to be \(features.count)")
        XCTAssertEqual(sut.features.first?.title, features.first?.title, "Expected first feature title to match")
    }
    
    func testCancellationStepsSubscriptionType_withGoogleSubscription_shouldReturnTypeGoogle() {
        let (sut, _) = makeSUT(currentSubscription: AccountSubscriptionEntity(paymentMethodId: .googleWallet))
        
        XCTAssertEqual(sut.cancellationStepsSubscriptionType, .google)
    }
    
    func testCancellationStepsSubscriptionType_withWebclientSubscription_shouldReturnTypeWebclient() {
        let nonWebclientMethods: [PaymentMethodEntity] = [.googleWallet, .itunes, .none]
        let webclientMethods = Set(PaymentMethodEntity.allCases).subtracting(Set(nonWebclientMethods))
        let randomPaymentMethod = webclientMethods.randomElement() ?? .stripe
        let (sut, _) = makeSUT(currentSubscription: AccountSubscriptionEntity(paymentMethodId: randomPaymentMethod))
        
        XCTAssertEqual(sut.cancellationStepsSubscriptionType, .webClient)
    }
    
    // MARK: - Private methods
    
    private func makeSUT(
        currentSubscription: AccountSubscriptionEntity = AccountSubscriptionEntity(id: "123"),
        currentPlanName: String = "",
        currentPlanStorageUsed: String = "",
        features: [FeatureDetails] = [],
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [.subscriptionCancellationSurvey: true]),
        tracker: some AnalyticsTracking = MockTracker(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        viewModel: CancelAccountPlanViewModel,
        router: MockCancelAccountPlanRouter
    ) {
        let router = MockCancelAccountPlanRouter()
        let viewModel = CancelAccountPlanViewModel(
            currentSubscription: currentSubscription,
            currentPlanName: currentPlanName,
            currentPlanStorageUsed: currentPlanStorageUsed,
            featureListHelper: MockFeatureListHelper(features: features),
            featureFlagProvider: featureFlagProvider,
            tracker: tracker,
            router: router
        )
        
        trackForMemoryLeaks(on: viewModel, file: file, line: line)
        return (viewModel, router)
    }
    
    private func performAnalyticsTest(
        action: (CancelAccountPlanViewModel) -> Void,
        expectedEvent: EventIdentifier
    ) {
        let mockTracker = MockTracker()
        let (sut, _) = makeSUT(tracker: mockTracker)
        
        action(sut)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: mockTracker.trackedEventIdentifiers,
            with: [expectedEvent]
        )
    }
}
