@testable import Accounts
import MEGAAppPresentationMock
import MEGADomain
import Testing

@Suite("PromoLandingDialogContentView.Dependency")
@MainActor
struct PromoLandingDialogContentViewDependencyTests {

    @Test("The only offer on the table leaves nothing to point at, so the upgrade page is not offered")
    func viewAllPlans_singleOffer_isHidden() {
        let sut = makeSUT(hasMultipleOffers: false)

        guard case .hidden = sut.viewAllPlans else {
            Issue.record("Expected the button to be hidden for a single offer")
            return
        }
    }

    @Test("Other plans on offer are reachable through the upgrade page")
    func viewAllPlans_multipleOffers_isShownWithTheAction() {
        var actionRan = false
        let sut = makeSUT(hasMultipleOffers: true, viewAllPlansAction: { actionRan = true })

        guard case .shown(let action) = sut.viewAllPlans else {
            Issue.record("Expected the button to be shown while other plans are on offer")
            return
        }

        action()

        #expect(actionRan)
    }

    @Test("The dialog is built around the promoted plan")
    func plan_whateverTheOfferCount_isThePromotedPlan() {
        let sut = makeSUT(hasMultipleOffers: true)

        #expect(sut.plan.type == .proI)
    }

    // MARK: - Helpers

    private func makeSUT(
        hasMultipleOffers: Bool,
        viewAllPlansAction: @escaping @MainActor () -> Void = {}
    ) -> PromoLandingDialogContentView.Dependency {
        PromoLandingDialogContentView.Dependency(
            fetchResult: fetchResult(hasMultipleOffers: hasMultipleOffers),
            planPurchaser: MockPlanPurchasing(),
            dismissAction: {},
            viewAllPlansAction: viewAllPlansAction
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
