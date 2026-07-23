import MEGADomain
import StoreKit

public struct StoreKitOfferRepository: StoreKitOfferRepositoryProtocol {
    public static var newRepo: StoreKitOfferRepository {
        StoreKitOfferRepository()
    }

    public init() {}

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: IntroductoryOfferEntity], promotional: [PlanEntity: PromotionalOfferEntity]) {
        let productIDs = plans.map(\.productIdentifier)

        guard let products = try? await Product.products(for: productIDs) else {
            return ([:], [:])
        }

        let productsByID: [String: Product] = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        return await withTaskGroup(
            of: (plan: PlanEntity, introductory: IntroductoryOfferEntity?, promotional: PromotionalOfferEntity?)?.self
        ) { group in
            for plan in plans {
                group.addTask {
                    guard let product = productsByID[plan.productIdentifier],
                          let subscription = product.subscription else {
                        return nil
                    }

                    var introductory: IntroductoryOfferEntity?
                    if await subscription.isEligibleForIntroOffer,
                       let offer = subscription.introductoryOffer {
                        introductory = IntroductoryOfferEntity.from(storeKitOffer: offer)
                    }

                    // Eligibility is backend-controlled: only a plan whose mobile offer carries a signed
                    // iOS payload is eligible; StoreKit only supplies the offer's billing schedule.
                    var promotional: PromotionalOfferEntity?
                    if plan.mobileOffer?.iosSignature != nil,
                       let offerId = plan.mobileOffer?.iosOfferId,
                       let offer = subscription.promotionalOffers.first(where: { $0.id == offerId }) {
                        promotional = PromotionalOfferEntity.from(storeKitOffer: offer)
                    }

                    guard introductory != nil || promotional != nil else { return nil }
                    return (plan, introductory, promotional)
                }
            }

            var introductoryOffers = [PlanEntity: IntroductoryOfferEntity]()
            var promotionalOffers = [PlanEntity: PromotionalOfferEntity]()
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
