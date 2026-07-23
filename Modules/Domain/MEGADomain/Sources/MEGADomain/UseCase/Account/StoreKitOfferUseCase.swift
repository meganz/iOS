public protocol StoreKitOfferUseCaseProtocol: Sendable {
    /// The eligible introductory and promotional offers for the given plans.
    func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: IntroductoryOfferEntity], promotional: [PlanEntity: PromotionalOfferEntity])
}

public struct StoreKitOfferUseCase<T: StoreKitOfferRepositoryProtocol>: StoreKitOfferUseCaseProtocol {
    private let repository: T

    public init(repository: T) {
        self.repository = repository
    }

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: IntroductoryOfferEntity], promotional: [PlanEntity: PromotionalOfferEntity]) {
        await repository.fetchOffers(for: plans)
    }
}
