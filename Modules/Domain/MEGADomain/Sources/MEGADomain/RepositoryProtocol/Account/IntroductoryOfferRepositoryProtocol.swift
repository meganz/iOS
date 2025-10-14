public protocol IntroductoryOfferRepositoryProtocol: RepositoryProtocol, Sendable {
    func fetchIntroductoryOffer(for productID: String) async -> IntroductoryOfferEntity?
}
