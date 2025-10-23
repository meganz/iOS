import MEGADomain
import StoreKit

public struct IntroductoryOfferRepository: IntroductoryOfferRepositoryProtocol {
    public static var newRepo: IntroductoryOfferRepository {
        IntroductoryOfferRepository()
    }

    public init() {}

    public func fetchIntroductoryOffers(for plans: [PlanEntity]) async -> [PlanEntity: IntroductoryOfferEntity] {
        let productIDs = plans.map(\.productIdentifier)

        guard let products = try? await Product.products(for: productIDs) else {
            return [:]
        }

        let productsByID: [String: Product] = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

        return await withTaskGroup(of: (PlanEntity, IntroductoryOfferEntity)?.self) { group in
            for plan in plans {
                group.addTask {
                    guard let product = productsByID[plan.productIdentifier],
                          let subscription = product.subscription,
                          await subscription.isEligibleForIntroOffer,
                          let offer = subscription.introductoryOffer,
                          let offerEntity = IntroductoryOfferEntity.from(storeKitOffer: offer) else {
                        return nil
                    }
                    return (plan, offerEntity)
                }
            }

            var collected = [PlanEntity: IntroductoryOfferEntity]()

            for await result in group {
                if let pair = result {
                    collected[pair.0] = pair.1
                }
            }

            return collected
        }
    }
}
