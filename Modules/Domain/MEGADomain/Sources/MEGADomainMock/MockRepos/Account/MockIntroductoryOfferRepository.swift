import MEGADomain

public final class MockIntroductoryOfferRepository: IntroductoryOfferRepositoryProtocol {
    public static var newRepo: MockIntroductoryOfferRepository {
        MockIntroductoryOfferRepository()
    }

    private let expectedMapping: [PlanEntity: IntroductoryOfferEntity]

    public init(expectedMapping: [PlanEntity: IntroductoryOfferEntity] = [:]) {
        self.expectedMapping = expectedMapping
    }

    public func fetchIntroductoryOffers(for plans: [PlanEntity]) async -> [PlanEntity: IntroductoryOfferEntity] {
        return expectedMapping
    }
}
