import MEGADomain

public final class MockIntroductoryOfferUseCase: IntroductoryOfferUseCaseProtocol {
    private let introductoryOffer: IntroductoryOfferEntity?

    public init(introductoryOffer: IntroductoryOfferEntity? = nil) {
        self.introductoryOffer = introductoryOffer
    }

    public func fetchIntroductoryOffer(for productID: String) async -> IntroductoryOfferEntity? {
        introductoryOffer
    }
}
