import MEGADomain
import StoreKit

public struct StoreKitOfferRepository: StoreKitOfferRepositoryProtocol {
    public static var newRepo: StoreKitOfferRepository {
        StoreKitOfferRepository()
    }

    private let eligibility: any StoreKitSubscriptionEligibilityChecking

    public init(eligibility: some StoreKitSubscriptionEligibilityChecking = StoreKitSubscriptionEligibility()) {
        self.eligibility = eligibility
    }

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: SubscriptionOfferEntity], promotional: [PlanEntity: SubscriptionOfferEntity]) {
        let productIDs = plans.map(\.productIdentifier)

        guard let products = try? await Product.products(for: productIDs) else {
            return ([:], [:])
        }

        let productsByID: [String: Product] = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        let eligibility = self.eligibility
        let isEligibleForPromotionalOffer = await eligibility.canRedeemPromotionalOffer()
        let activeGroupIDs = await eligibility.activeSubscriptionGroupIDs()

        return await withTaskGroup(
            of: (plan: PlanEntity, introductory: SubscriptionOfferEntity?, promotional: SubscriptionOfferEntity?)?.self
        ) { group in
            for plan in plans {
                group.addTask {
                    guard let product = productsByID[plan.productIdentifier],
                          let subscription = product.subscription else {
                        return nil
                    }

                    var introductory: SubscriptionOfferEntity?
                    if await eligibility.isIntroductoryOfferRedeemable(
                        for: subscription,
                        activeGroupIDs: activeGroupIDs
                    ), let offer = subscription.introductoryOffer {
                        introductory = SubscriptionOfferEntity.from(storeKitOffer: offer)
                    }

                    var promotional: SubscriptionOfferEntity?
                    if isEligibleForPromotionalOffer,
                       plan.mobileOffer?.iosSignature != nil,
                       let offerId = plan.mobileOffer?.iosOfferId,
                       let offer = subscription.promotionalOffers.first(where: { $0.id == offerId }) {
                        promotional = SubscriptionOfferEntity.from(storeKitOffer: offer)
                    }

                    guard introductory != nil || promotional != nil else { return nil }
                    return (plan, introductory, promotional)
                }
            }

            var introductoryOffers = [PlanEntity: SubscriptionOfferEntity]()
            var promotionalOffers = [PlanEntity: SubscriptionOfferEntity]()
            for await result in group {
                guard let result else { continue }
                if let introductory = result.introductory {
                    introductoryOffers[result.plan] = introductory
                }
                if let promotional = result.promotional {
                    promotionalOffers[result.plan] = promotional
                }
            }

            return (introductoryOffers, promotionalOffers)
        }
    }

}
