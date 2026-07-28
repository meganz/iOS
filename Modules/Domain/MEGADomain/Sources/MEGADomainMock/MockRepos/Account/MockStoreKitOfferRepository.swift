import MEGADomain

public final class MockStoreKitOfferRepository: StoreKitOfferRepositoryProtocol {
    public static var newRepo: MockStoreKitOfferRepository {
        MockStoreKitOfferRepository()
    }

    private let expectedMapping: [PlanEntity: SubscriptionOfferEntity]
    private let expectedPromotionalMapping: [PlanEntity: SubscriptionOfferEntity]

    public init(
        expectedMapping: [PlanEntity: SubscriptionOfferEntity] = [:],
        expectedPromotionalMapping: [PlanEntity: SubscriptionOfferEntity] = [:]
    ) {
        self.expectedMapping = expectedMapping
        self.expectedPromotionalMapping = expectedPromotionalMapping
    }

    public func fetchOffers(
        for plans: [PlanEntity]
    ) async -> (introductory: [PlanEntity: SubscriptionOfferEntity], promotional: [PlanEntity: SubscriptionOfferEntity]) {
        (expectedMapping, expectedPromotionalMapping)
    }
}
