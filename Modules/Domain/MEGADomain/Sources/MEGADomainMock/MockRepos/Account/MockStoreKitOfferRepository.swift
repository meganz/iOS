import MEGADomain

public final class MockStoreKitOfferRepository: StoreKitOfferRepositoryProtocol {
    public static var newRepo: MockStoreKitOfferRepository {
        MockStoreKitOfferRepository()
    }

    private let expectedMapping: [PlanEntity: IntroductoryOfferEntity]
    private let expectedPromotionalMapping: [PlanEntity: PromotionalOfferEntity]

    public init(
        expectedMapping: [PlanEntity: IntroductoryOfferEntity] = [:],
        expectedPromotionalMapping: [PlanEntity: PromotionalOfferEntity] = [:]
    ) {
        self.expectedMapping = expectedMapping
        self.expectedPromotionalMapping = expectedPromotionalMapping
    }

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: IntroductoryOfferEntity], promotional: [PlanEntity: PromotionalOfferEntity]) {
        (expectedMapping, expectedPromotionalMapping)
    }
}
