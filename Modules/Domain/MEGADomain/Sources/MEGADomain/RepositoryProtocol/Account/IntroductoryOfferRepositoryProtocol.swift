public protocol IntroductoryOfferRepositoryProtocol: RepositoryProtocol, Sendable {
    func fetchIntroductoryOffers(for plans: [PlanEntity]) async -> [PlanEntity: IntroductoryOfferEntity]
}
