import MEGADomain

public final class MockStoreKitOfferUseCase: StoreKitOfferUseCaseProtocol {
    private let introductoryOfferDict: [PlanEntity: IntroductoryOfferEntity]
    private let promotionalOfferDict: [PlanEntity: PromotionalOfferEntity]

    public init(
        introductoryOfferDict: [PlanEntity: IntroductoryOfferEntity] = [PlanEntity: IntroductoryOfferEntity](),
        promotionalOfferDict: [PlanEntity: PromotionalOfferEntity] = [PlanEntity: PromotionalOfferEntity]()
    ) {
        self.introductoryOfferDict = introductoryOfferDict
        self.promotionalOfferDict = promotionalOfferDict
    }

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: IntroductoryOfferEntity], promotional: [PlanEntity: PromotionalOfferEntity]) {
        (introductoryOfferDict, promotionalOfferDict)
    }
}
