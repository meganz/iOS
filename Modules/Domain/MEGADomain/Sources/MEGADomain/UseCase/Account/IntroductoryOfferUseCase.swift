public protocol IntroductoryOfferUseCaseProtocol: Sendable {
    func fetchIntroductoryOffer(for productID: String) async -> IntroductoryOfferEntity?
}

public struct IntroductoryOfferUseCase<T: IntroductoryOfferRepositoryProtocol>: IntroductoryOfferUseCaseProtocol {
    private let repository: T

    public init(repository: T) {
        self.repository = repository
    }
    public func fetchIntroductoryOffer(for productID: String) async -> IntroductoryOfferEntity? {
        await repository.fetchIntroductoryOffer(for: productID)
    }
}
