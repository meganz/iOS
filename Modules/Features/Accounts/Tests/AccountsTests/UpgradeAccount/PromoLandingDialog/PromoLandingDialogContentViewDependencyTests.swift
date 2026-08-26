@testable import Accounts
import MEGAAppPresentationMock
import MEGADomain
import Testing

@Suite("PromoLandingDialogContentView.Dependency")
@MainActor
struct PromoLandingDialogContentViewDependencyTests {

    @Test("Whether other plans are on offer is carried over from the fetch result", arguments: [true, false])
    func hasMultipleOffers_isCarriedFromTheFetchResult(hasMultipleOffers: Bool) {
        let sut = makeSUT(hasMultipleOffers: hasMultipleOffers)

        #expect(sut.hasMultipleOffers == hasMultipleOffers)
    }

    @Test("The dialog is built around the promoted plan")
    func plan_whateverTheOfferCount_isThePromotedPlan() {
        let sut = makeSUT(hasMultipleOffers: true)

        #expect(sut.plan.type == .proI)
    }

    // MARK: - Helpers

    private func makeSUT(
        hasMultipleOffers: Bool,
        viewAllPlansAction: @escaping @MainActor () -> Void = {},
        tracker: MockTracker = MockTracker()
    ) -> PromoLandingDialogContentView.Dependency {
        PromoLandingDialogContentView.Dependency(
            fetchResult: fetchResult(hasMultipleOffers: hasMultipleOffers),
            launchSource: .userTriggered,
            planPurchaser: MockPlanPurchasing(),
            dismissAction: {},
            viewAllPlansAction: viewAllPlansAction,
            makePromoExpiryTimer: PromoExpiryTimer.init(deadline:),
            tracker: tracker
        )
    }

    private func fetchResult(hasMultipleOffers: Bool) -> PromotedPlanFetchResult {
        let offer = MobileOfferEntity(
            id: "black-friday-2026",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 1,
            reshowTimeout: nil,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil,
            campaignId: 2026
        )
        return PromotedPlanFetchResult(
            promotedPlan: PromotedPlanEntity(
                plan: PlanEntity(
                    type: .proI,
                    appStorePrice: PlanPriceEntity(price: 100, formattedPrice: "", currency: "USD"),
                    mobileOffer: offer
                ),
                offer: offer
            ),
            hasMultipleOffers: hasMultipleOffers
        )
    }
}
