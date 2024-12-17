@testable import Accounts
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import Testing

struct AdsFreeViewModelTestSuite {
    // MARK: - Helper
    @MainActor
    private static func makeSUT(
        lowestPlan: PlanEntity = PlanEntity(),
        viewProPlanAction: (() -> Void)? = nil,
        tracker: some AnalyticsTracking = MockTracker()
    ) -> AdsFreeViewModel {
        AdsFreeViewModel(
            purchaseUseCase: MockAccountPlanPurchaseUseCase(lowestPlan: lowestPlan),
            tracker: tracker,
            viewProPlanAction: viewProPlanAction
        )
    }

    // MARK: - Tests
    @Suite("Lowest pro plan tests")
    struct LowestProPlan {
        @MainActor
        @Test(
            "Set the lowest pro plan available",
            arguments: [
                PlanEntity(type: .lite, subscriptionCycle: .monthly, price: 1),
                PlanEntity(type: .proI, subscriptionCycle: .monthly, price: 2),
                PlanEntity(type: .proII, subscriptionCycle: .monthly, price: 3)
            ]
        )
        func setUpLowestProPlan(plan: PlanEntity) async {
            let sut = makeSUT(lowestPlan: plan)
            
            await sut.setUpLowestProPlan()
            
            #expect(sut.lowestProPlan == plan, "Expected lowest pro plan is \(plan)")
        }
    }
    
    @Suite("Ads-free button actions")
    struct AdsFreeButtonActions {
        @MainActor
        @Test("Perform provided action for View Pro Plans button when tapped")
        func didTapViewProPlansButton() {
            var buttonTapped = false
            
            let sut = makeSUT(viewProPlanAction: {
                buttonTapped = true
            })
            
            sut.didTapViewProPlansButton()
            
            #expect(buttonTapped, "Expected to call viewProPlanAction on tapping the button")
        }
    }
    
    @Suite("Track analytics events")
    struct AdsFreeViewEvents {
        @MainActor
        private func assertTrackEvent(
            sutAction: (AdsFreeViewModel) -> Void,
            expectedEvent: any EventIdentifier
        ) {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker)
            
            sutAction(sut)
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [expectedEvent]
            )
        }
        
        @MainActor
        @Test func trackOnAppear() {
            assertTrackEvent(
                sutAction: { $0.onAppear() },
                expectedEvent: AdFreeDialogScreenEvent()
            )
        }
        
        @MainActor
        @Test func trackViewProPlansButtonTap() {
            assertTrackEvent(
                sutAction: { $0.didTapViewProPlansButton() },
                expectedEvent: AdFreeDialogScreenViewProPlansButtonPressedEvent()
            )
        }
        
        @MainActor
        @Test func trackSkipButtonTap() {
            assertTrackEvent(
                sutAction: { $0.didTapSkipButton() },
                expectedEvent: AdFreeDialogScreenSkipButtonPressedEvent()
            )
        }
    }
}
