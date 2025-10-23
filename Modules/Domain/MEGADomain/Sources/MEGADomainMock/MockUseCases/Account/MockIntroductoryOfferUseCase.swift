import MEGADomain

public final class MockIntroductoryOfferUseCase: IntroductoryOfferUseCaseProtocol {
    private let introductoryOfferDict: [PlanEntity: IntroductoryOfferEntity]

    public init(introductoryOfferDict: [PlanEntity: IntroductoryOfferEntity] = [PlanEntity: IntroductoryOfferEntity]()) {
        self.introductoryOfferDict = introductoryOfferDict
    }

    public func fetchIntroductoryOffers(for plans: [PlanEntity]) async -> [PlanEntity: IntroductoryOfferEntity] {
        introductoryOfferDict
    }
}
