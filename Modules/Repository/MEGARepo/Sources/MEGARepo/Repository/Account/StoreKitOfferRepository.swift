import MEGADomain
import StoreKit

public struct StoreKitOfferRepository: StoreKitOfferRepositoryProtocol {
    public static var newRepo: StoreKitOfferRepository {
        StoreKitOfferRepository()
    }

    public init() {}

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: SubscriptionOfferEntity], promotional: [PlanEntity: SubscriptionOfferEntity]) {
        let productIDs = plans.map(\.productIdentifier)

        guard let products = try? await Product.products(for: productIDs) else {
            return ([:], [:])
        }

        let productsByID: [String: Product] = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

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
                    if await subscription.isEligibleForIntroOffer,
                       let offer = subscription.introductoryOffer {
                        introductory = SubscriptionOfferEntity.from(storeKitOffer: offer)
                    }

                    // Eligibility is backend-controlled: only a plan whose mobile offer carries a signed
                    // iOS payload is eligible; StoreKit only supplies the offer's billing schedule.
                    var promotional: SubscriptionOfferEntity?
                    if plan.mobileOffer?.iosSignature != nil,
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

            // Technically user can see both Introductory offers and Promotional offers at the same time.
            // However according to Apple's rule: If a user is eligible for introductory offers (aka he's a new user), he won't be able to
            // redeemed promotional offers. When an intro-offer-eligible user buys a products, Appstore automatically apply the offer's discount to that purchase
            // regardless of the present of promo offer.
            // In verdict: When there's is at least one introductory offer, we discard the promotional offers as they're now non-redeemable.
            // Caveat: This scrapping logic is only correct as long as our app has only 1 subscription group. If in the
            // furure we have more subscription groups we'll need to update the logic.
            // Ref: https://developer.apple.com/documentation/storekit/setting-up-promotional-offers (see the `Note` section) at the beginning of the page
            if !introductoryOffers.isEmpty {
                return (introductoryOffers, [:])
            } else {
                return ([:], promotionalOffers)
            }
        }
    }
}
