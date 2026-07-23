public protocol StoreKitOfferRepositoryProtocol: RepositoryProtocol, Sendable {
    /// The eligible introductory and promotional offers for the given plans, resolved in one StoreKit fetch.
    func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: IntroductoryOfferEntity], promotional: [PlanEntity: PromotionalOfferEntity])
}
