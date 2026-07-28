import MEGADomain

public final class MockStoreKitOfferUseCase: StoreKitOfferUseCaseProtocol {
    private let introductoryOfferDict: [PlanEntity: SubscriptionOfferEntity]
    private let promotionalOfferDict: [PlanEntity: SubscriptionOfferEntity]

    public init(
        introductoryOfferDict: [PlanEntity: SubscriptionOfferEntity] = [PlanEntity: SubscriptionOfferEntity](),
        promotionalOfferDict: [PlanEntity: SubscriptionOfferEntity] = [PlanEntity: SubscriptionOfferEntity]()
    ) {
        self.introductoryOfferDict = introductoryOfferDict
        self.promotionalOfferDict = promotionalOfferDict
    }

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: SubscriptionOfferEntity], promotional: [PlanEntity: SubscriptionOfferEntity]) {
        (introductoryOfferDict, promotionalOfferDict)
    }
}
