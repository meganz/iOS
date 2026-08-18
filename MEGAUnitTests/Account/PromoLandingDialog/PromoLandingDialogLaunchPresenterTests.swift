@testable import Accounts
@testable import MEGA
import MEGADomain
import MEGASwift
import Testing

@Suite("PromoLandingDialogLaunchPresenter")
@MainActor
struct PromoLandingDialogLaunchPresenterTests {

    @Test("An app open the user can be interrupted on presents the promoted plan and records the showing")
    func triggerIfNeeded_interruptibleWithPromotedPlan_presentsAndRecords() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan())
        let presentation = PresentationSpy(result: true)
        let sut = makeSUT(useCase: useCase, canInterruptUser: true, presentation: presentation)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(presentation.presentedPlans.count == 1)
        #expect(useCase.recordedPlans.count == 1)
    }

    @Test("The dialog is handed the whole fetch result, so it can point at the other plans on offer")
    func triggerIfNeeded_multipleOffers_presentsThatVerdict() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan(), hasMultipleOffers: true)
        let presentation = PresentationSpy(result: true)
        let sut = makeSUT(useCase: useCase, canInterruptUser: true, presentation: presentation)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(presentation.presentedResults.map(\.hasMultipleOffers) == [true])
    }

    @Test("The dialog belongs to the plan revamp, so nothing happens while that flag is off")
    func triggerIfNeeded_featureDisabled_doesNotResolveOrPresent() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan())
        let presentation = PresentationSpy(result: true)
        let sut = makeSUT(useCase: useCase, canInterruptUser: true, presentation: presentation, isFeatureEnabled: false)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(useCase.promotedPlanToPresentCalled == 0)
        #expect(presentation.presentedPlans.isEmpty)
        #expect(useCase.recordedPlans.isEmpty)
    }

    @Test("Nothing is presented when the user must not be interrupted, and no offer is even resolved")
    func triggerIfNeeded_notInterruptible_doesNotResolveOrPresent() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan())
        let presentation = PresentationSpy(result: true)
        let sut = makeSUT(useCase: useCase, canInterruptUser: false, presentation: presentation)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(useCase.promotedPlanToPresentCalled == 0)
        #expect(presentation.presentedPlans.isEmpty)
    }

    @Test("Interruptibility is checked again after the delay, so a screen the user moved onto still stops the dialog")
    func triggerIfNeeded_becomesUninterruptibleDuringTheDelay_doesNotPresent() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan())
        let presentation = PresentationSpy(result: true)
        let interruptibility = MockInterruptibility(canInterruptUser: true)
        let sut = PromoLandingDialogLaunchPresenter(
            isFeatureEnabled: { true },
            useCase: useCase,
            interruptibility: interruptibility,
            presentDialog: presentation.present,
            // Standing in for the wait: whatever happens during it, interruptibility is read again afterwards.
            delay: { await MainActor.run { interruptibility.canInterruptUser = false } }
        )

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(presentation.presentedPlans.isEmpty)
    }

    @Test("Interruptibility is checked again after the offer is resolved, so a slow lookup cannot outrun the check")
    func triggerIfNeeded_becomesUninterruptibleDuringTheLookup_doesNotPresent() async {
        let interruptibility = MockInterruptibility(canInterruptUser: true)
        // Standing in for the pricing request: the user walks onto a call while it is in flight.
        let useCase = MockAppOpenPromoDialogUseCase(
            promotedPlan: plan(),
            onResolve: { await MainActor.run { interruptibility.canInterruptUser = false } }
        )
        let presentation = PresentationSpy(result: true)
        let sut = PromoLandingDialogLaunchPresenter(
            isFeatureEnabled: { true },
            useCase: useCase,
            interruptibility: interruptibility,
            presentDialog: presentation.present,
            delay: {}
        )

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(useCase.promotedPlanToPresentCalled == 1)
        #expect(presentation.presentedPlans.isEmpty)
        #expect(useCase.recordedPlans.isEmpty)
    }

    @Test("A campaign with no showing to make leaves the allowance alone")
    func triggerIfNeeded_noPromotedPlan_recordsNothing() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: nil)
        let presentation = PresentationSpy(result: true)
        let sut = makeSUT(useCase: useCase, canInterruptUser: true, presentation: presentation)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(presentation.presentedPlans.isEmpty)
        #expect(useCase.recordedPlans.isEmpty)
    }

    @Test("A presentation that did not happen does not spend the reshow allowance")
    func triggerIfNeeded_presentationRefused_recordsNothing() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan())
        let presentation = PresentationSpy(result: false)
        let sut = makeSUT(useCase: useCase, canInterruptUser: true, presentation: presentation)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(presentation.presentedPlans.count == 1)
        #expect(useCase.recordedPlans.isEmpty)
    }

    @Test("A failed offer lookup is swallowed rather than surfaced on an unprompted dialog")
    func triggerIfNeeded_lookupThrows_presentsNothing() async {
        let useCase = MockAppOpenPromoDialogUseCase(error: TestError.any)
        let presentation = PresentationSpy(result: true)
        let sut = makeSUT(useCase: useCase, canInterruptUser: true, presentation: presentation)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(presentation.presentedPlans.isEmpty)
        #expect(useCase.recordedPlans.isEmpty)
    }

    @Test("Cancelling before the wait ends drops the attempt")
    func cancel_duringTheDelay_doesNotPresent() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan())
        let presentation = PresentationSpy(result: true)
        let sut = PromoLandingDialogLaunchPresenter(
            isFeatureEnabled: { true },
            useCase: useCase,
            interruptibility: MockInterruptibility(canInterruptUser: true),
            presentDialog: presentation.present,
            delay: { try await Task.sleep(for: .seconds(30)) }
        )

        sut.triggerIfNeeded()
        let attempt = sut.attempt
        sut.cancel()
        await attempt?.value

        #expect(presentation.presentedPlans.isEmpty)
        #expect(sut.attempt == nil)
    }

    /// The offer lookup refreshes pricing against both the API and StoreKit, so it is long enough for the user
    /// to background the app part way through it. The cancellation check after the lookup is what stops a dialog
    /// being presented into an app nobody is looking at; without it a resolved offer would go straight on screen.
    /// Cancelling from inside the lookup is how the attempt is cancelled mid-flight without racing the test.
    @Test("Backgrounding while the offer is being resolved drops the attempt rather than presenting")
    func cancel_duringTheOfferLookup_doesNotPresent() async {
        let useCase = MockAppOpenPromoDialogUseCase(
            promotedPlan: plan(),
            onResolve: { withUnsafeCurrentTask { $0?.cancel() } }
        )
        let presentation = PresentationSpy(result: true)
        let sut = makeSUT(useCase: useCase, canInterruptUser: true, presentation: presentation)

        sut.triggerIfNeeded()
        await sut.attempt?.value

        #expect(useCase.promotedPlanToPresentCalled == 1)
        #expect(presentation.presentedPlans.isEmpty)
        #expect(useCase.recordedPlans.isEmpty)
    }

    @Test("A second trigger replaces the pending attempt instead of stacking a second dialog")
    func triggerIfNeeded_twice_presentsOnce() async {
        let useCase = MockAppOpenPromoDialogUseCase(promotedPlan: plan())
        let presentation = PresentationSpy(result: true)
        let sut = PromoLandingDialogLaunchPresenter(
            isFeatureEnabled: { true },
            useCase: useCase,
            interruptibility: MockInterruptibility(canInterruptUser: true),
            presentDialog: presentation.present,
            delay: { try await Task.sleep(for: .milliseconds(10)) }
        )

        sut.triggerIfNeeded()
        let firstAttempt = sut.attempt
        sut.triggerIfNeeded()
        await firstAttempt?.value
        await sut.attempt?.value

        #expect(presentation.presentedPlans.count == 1)
    }

    // MARK: - Helpers

    private func makeSUT(
        useCase: MockAppOpenPromoDialogUseCase,
        canInterruptUser: Bool,
        presentation: PresentationSpy,
        isFeatureEnabled: Bool = true
    ) -> PromoLandingDialogLaunchPresenter {
        PromoLandingDialogLaunchPresenter(
            isFeatureEnabled: { isFeatureEnabled },
            useCase: useCase,
            interruptibility: MockInterruptibility(canInterruptUser: canInterruptUser),
            presentDialog: presentation.present,
            delay: {}
        )
    }

    private func plan() -> PromotedPlanEntity {
        let offer = MobileOfferEntity(
            id: "black-friday-2026",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 1,
            reshowTimeout: 3600,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil,
            campaignId: 2026
        )
        return PromotedPlanEntity(
            plan: PlanEntity(
                type: .proI,
                appStorePrice: PlanPriceEntity(price: 100, formattedPrice: "", currency: "USD"),
                mobileOffer: offer
            ),
            offer: offer
        )
    }
}

// MARK: - Test doubles

private enum TestError: Error {
    case any
}

@MainActor
private final class MockInterruptibility: PromoDialogInterruptibilityProtocol {
    var canInterruptUser: Bool

    init(canInterruptUser: Bool) {
        self.canInterruptUser = canInterruptUser
    }
}

private final class MockAppOpenPromoDialogUseCase: AppOpenPromoDialogUseCaseProtocol, @unchecked Sendable {
    @Atomic var promotedPlanToPresentCalled = 0
    @Atomic var recordedPlans: [PromotedPlanEntity] = []

    private let fetchResult: PromotedPlanFetchResult?
    private let error: (any Error)?
    /// Runs while the offer is being resolved, standing in for whatever the user does during the request.
    private let onResolve: (@Sendable () async -> Void)?

    init(
        promotedPlan: PromotedPlanEntity? = nil,
        hasMultipleOffers: Bool = false,
        error: (any Error)? = nil,
        onResolve: (@Sendable () async -> Void)? = nil
    ) {
        self.fetchResult = promotedPlan.map {
            PromotedPlanFetchResult(promotedPlan: $0, hasMultipleOffers: hasMultipleOffers)
        }
        self.error = error
        self.onResolve = onResolve
    }

    func promotedPlanToPresent() async throws -> PromotedPlanFetchResult? {
        $promotedPlanToPresentCalled.mutate { $0 += 1 }
        await onResolve?()
        if let error {
            throw error
        }
        return fetchResult
    }

    func recordDialogShown(for promotedPlan: PromotedPlanEntity) {
        $recordedPlans.mutate { $0.append(promotedPlan) }
    }
}

/// Records what the presenter tried to present, standing in for the router.
@MainActor
private final class PresentationSpy {
    private(set) var presentedResults: [PromotedPlanFetchResult] = []

    var presentedPlans: [PlanEntity] { presentedResults.map(\.promotedPlan.plan) }

    private let result: Bool

    init(result: Bool) {
        self.result = result
    }

    var present: @MainActor (PromotedPlanFetchResult) -> Bool {
        { [self] fetchResult in
            presentedResults.append(fetchResult)
            return result
        }
    }
}
