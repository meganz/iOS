@testable import Accounts
import AccountsMock
import MEGAAnalyticsiOS
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class CancelAccountPlanViewModelTests: XCTestCase {
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

    func testShowCancelSubscriptionSteps_shouldTrackAnalyticsEvent() {
        performAnalyticsTest(action: { sut in
            sut.showCancelSubscriptionSteps()
        }, expectedEvent: CancelSubscriptionContinueCancellationButtonPressedEvent())
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
    
    func testDismiss_shouldCallRouterDismiss() {
        let (sut, router) = makeSUT(features: features)
        
        sut.dismiss()
        
        XCTAssertEqual(router.dismiss_calledTimes, 1, "Expected dismiss to be called on router")
    }
    
    func testShowCancelSubscriptionSteps_shouldCallRouterShowCancelSubscriptionSteps() {
        let (sut, router) = makeSUT(features: features)
        
        sut.showCancelSubscriptionSteps()
        
        XCTAssertEqual(router.showCancellationSteps_calledTimes, 1, "Expected showCancelSubscriptionSteps to be called on router")
    }
    
    // MARK: - Private methods
    
    private func makeSUT(
        currentPlanName: String = "",
        currentPlanStorageUsed: String = "",
        features: [FeatureDetails] = [],
        tracker: some AnalyticsTracking = MockTracker()
    ) -> (
        viewModel: CancelAccountPlanViewModel,
        router: MockCancelAccountPlanRouter
    ) {
        let router = MockCancelAccountPlanRouter()
        let viewModel = CancelAccountPlanViewModel(
            currentPlanName: currentPlanName,
            currentPlanStorageUsed: currentPlanStorageUsed,
            featureListHelper: MockFeatureListHelper(features: features),
            tracker: tracker,
            router: router
        )
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
