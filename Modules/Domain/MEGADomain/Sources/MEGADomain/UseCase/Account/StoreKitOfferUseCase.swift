public protocol StoreKitOfferUseCaseProtocol: Sendable {
    /// The eligible introductory and promotional offers for the given plans.
    func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: SubscriptionOfferEntity], promotional: [PlanEntity: SubscriptionOfferEntity])
}

public struct StoreKitOfferUseCase<T: StoreKitOfferRepositoryProtocol>: StoreKitOfferUseCaseProtocol {
    private let repository: T

    public init(repository: T) {
        self.repository = repository
    }

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: SubscriptionOfferEntity], promotional: [PlanEntity: SubscriptionOfferEntity]) {
        await repository.fetchOffers(for: plans)
    }
}
