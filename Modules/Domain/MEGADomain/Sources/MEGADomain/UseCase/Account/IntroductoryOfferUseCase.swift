public protocol IntroductoryOfferUseCaseProtocol: Sendable {
    func fetchIntroductoryOffers(for plans: [PlanEntity]) async -> [PlanEntity: IntroductoryOfferEntity]
}

public struct IntroductoryOfferUseCase<T: IntroductoryOfferRepositoryProtocol>: IntroductoryOfferUseCaseProtocol {
    private let repository: T

    public init(repository: T) {
        self.repository = repository
    }

    public func fetchIntroductoryOffers(for plans: [PlanEntity]) async -> [PlanEntity: IntroductoryOfferEntity] {
        await repository.fetchIntroductoryOffers(for: plans)
    }
}
