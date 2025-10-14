import MEGADomain
import StoreKit

public struct IntroductoryOfferRepository: IntroductoryOfferRepositoryProtocol {
    public static var newRepo: IntroductoryOfferRepository {
        IntroductoryOfferRepository()
    }

    public init() {}

    public func fetchIntroductoryOffer(for productID: String) async -> IntroductoryOfferEntity? {
        guard let product = try? await Product.products(for: [productID]).first,
              let subscription = product.subscription,
              await subscription.isEligibleForIntroOffer,
              let offer = subscription.introductoryOffer else {
            return nil
        }

        return IntroductoryOfferEntity.from(storeKitOffer: offer)
    }
}
