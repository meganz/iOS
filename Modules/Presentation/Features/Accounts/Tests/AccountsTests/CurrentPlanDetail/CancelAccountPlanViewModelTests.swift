@testable import Accounts
import AccountsMock
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
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
    
    @MainActor func testDismiss_shouldTrackAnalyticsEvent() {
        performAnalyticsTest(action: { sut in
            sut.dismiss()
        }, expectedEvent: CancelSubscriptionKeepPlanButtonPressedEvent())
    }
    
    @MainActor func testDismiss_shouldDismissCancellationFlow() {
        let (sut, router) = makeSUT()
        
        sut.dismiss()
        
        XCTAssertEqual(router.dismissCancellationFlow_calledTimes, 1, "Expected dismissCancellationFlow to be called on router")
    }
    
    func testDidTapContinueCancellation_subscriptionPaymentMethodIsGoogleWallet_shouldShowCancellationSteps() async {
        let (sut, _) = makeSUT(currentSubscription: AccountSubscriptionEntity(paymentMethodId: .googleWallet))
        
        await assertDidTapContinueCancellation(
            sut: sut,
            publisher: sut.$showCancellationSteps,
            expectedVisibility: true
        )
        XCTAssertFalse(sut.showCancellationSurvey)
    }

    func testDidTapContinueCancellation_subscriptionPaymentMethodIsItunes_shouldShowCancellationSurvey() async {
        await assertContinueCancellation(
            for: .itunes,
            expectedVisibility: true
        )
    }

    func testDidTapContinueCancellation_subscriptionPaymentMethodIsAnyWebClientMethodAndWebclientCancellationInAppIsNotEnabled_shouldShowCancellationSurvey() async {
        let (sut, _) = makeSUT(currentSubscription: AccountSubscriptionEntity(paymentMethodId: randomWebClientPaymentMethod()))
        
        await assertDidTapContinueCancellation(
            sut: sut,
            publisher: sut.$showCancellationSteps,
            expectedVisibility: true
        )
        XCTAssertFalse(sut.showCancellationSurvey)
    }
    
    func testDidTapContinueCancellation_subscriptionPaymentMethodIsAnyWebClientMethodAndWebclientCancellationInAppIsEnabled_shouldShowCancellationSurvey() async {
        await assertContinueCancellation(
            for: randomWebClientPaymentMethod(),
            isWebclientSubscriptionCancellationEnabled: true,
            expectedVisibility: true
        )
    }
    
    func testSetupFeatureList_freeAccountStorageLimitAboveZero_shouldSetFeatures() async {
        let (sut, _) = makeSUT(
            freeAccountStorageLimit: 20,
            features: features
        )
        
        await sut.setupFeatureList()
        
        XCTAssertEqual(sut.features.count, features.count, "Expected features count to be \(features.count)")
        XCTAssertEqual(sut.features.first?.title, features.first?.title, "Expected first feature title to match")
    }

    @MainActor func testSetupFeatureList_freeAccountStorageLimitZero_shouldDismiss() async {
        let (sut, router) = makeSUT(freeAccountStorageLimit: 0)
        
        await sut.setupFeatureList()
        
        XCTAssertEqual(router.dismissCancellationFlow_calledTimes, 1, "Expected dismissCancellationFlow to be called when storage limit is zero")
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
        let proLevel: AccountTypeEntity = .proI
        let expectedName = proLevel.toAccountTypeDisplayName()
        let storageUsed: Int64 = 400
        let expectedStorage = String.memoryStyleString(fromByteCount: storageUsed)
        let (sut, _) = makeSUT(
            proLevel: proLevel,
            storageUsed: storageUsed,
            freeAccountStorageLimit: 20,
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
    
    @MainActor func testMakeCancellationSurveyViewModel_shouldHaveCorrectSubscription() {
        let expectedSubscription = AccountSubscriptionEntity(id: "ABC123")
        let (sut, _) = makeSUT(currentSubscription: expectedSubscription)
        
        let viewModel = sut.makeCancellationSurveyViewModel()
        
        XCTAssertEqual(viewModel.subscription, expectedSubscription)
    }
    
    // MARK: - Private methods
    
    private func makeSUT(
        currentSubscription: AccountSubscriptionEntity = AccountSubscriptionEntity(id: "123"),
        proLevel: AccountTypeEntity = .free,
        storageUsed: Int64 = 0,
        freeAccountStorageLimit: Int = 0,
        features: [FeatureDetails] = [],
        tracker: some AnalyticsTracking = MockTracker(),
        featureFlagList: [FeatureFlagKey: Bool] = [:],
        file: StaticString = #file,
        line: UInt = #line
    ) -> (
        viewModel: CancelAccountPlanViewModel,
        router: MockCancelAccountPlanRouter
    ) {
        let accountDetails = AccountDetailsEntity.build(
            storageUsed: storageUsed,
            proLevel: proLevel
        )
        let router = MockCancelAccountPlanRouter()
        let viewModel = CancelAccountPlanViewModel(
            currentSubscription: currentSubscription,
            featureListHelper: MockFeatureListHelper(features: features),
            freeAccountStorageLimit: freeAccountStorageLimit,
            achievementUseCase: MockAchievementUseCase(),
            accountUseCase: MockAccountUseCase(currentAccountDetails: accountDetails),
            tracker: tracker,
            featureFlagProvider: MockFeatureFlagProvider(list: featureFlagList),
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
    
    private func randomWebClientPaymentMethod() -> PaymentMethodEntity {
        PaymentMethodEntity
            .allCases
            .filter { $0 != .itunes && $0 != .googleWallet }
            .randomElement() ?? .stripe
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
    
    private func assertContinueCancellation(
        for paymentMethod: PaymentMethodEntity,
        isWebclientSubscriptionCancellationEnabled: Bool = false,
        expectedVisibility: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let (sut, _) = makeSUT(
            currentSubscription: AccountSubscriptionEntity(paymentMethodId: paymentMethod),
            featureFlagList: isWebclientSubscriptionCancellationEnabled ? [.webclientSubscribersCancelSubscription: true] : [:]
        )
        
        await assertDidTapContinueCancellation(
            sut: sut,
            publisher: sut.$showCancellationSurvey,
            expectedVisibility: expectedVisibility
        )
        XCTAssertFalse(sut.showCancellationSteps, file: file, line: line)
    }
}
