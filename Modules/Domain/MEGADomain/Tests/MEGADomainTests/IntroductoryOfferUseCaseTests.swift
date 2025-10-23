import MEGADomain
import MEGADomainMock
import Testing

@MainActor
struct IntroductoryOfferUseCaseTests {
    @Test
    func fetchIntroductoryOffers_withMultiplePlans_shouldReturnOfferMapping() async {
        let plan1 = PlanEntity(productIdentifier: "plan1", type: .proI, subscriptionCycle: .yearly)
        let plan2 = PlanEntity(productIdentifier: "plan2", type: .proII, subscriptionCycle: .yearly)
        let plan3 = PlanEntity(productIdentifier: "plan3", type: .proIII, subscriptionCycle: .monthly)
        
        let offer1 = IntroductoryOfferEntity(
            price: 80,
            period: .init(unit: .year, value: 1),
            periodCount: 1
        )
        let offer2 = IntroductoryOfferEntity(
            price: 8,
            period: .init(unit: .month, value: 1),
            periodCount: 3
        )
        
        let expectedMapping = [plan1: offer1, plan2: offer2]
        let mockRepo = MockIntroductoryOfferRepository(expectedMapping: expectedMapping)
        let sut = IntroductoryOfferUseCase(repository: mockRepo)
        
        let result = await sut.fetchIntroductoryOffers(for: [plan1, plan2, plan3])
        
        #expect(result.count == 2)
        #expect(result[plan1] == offer1)
        #expect(result[plan2] == offer2)
        #expect(result[plan3] == nil)
    }
    
    @Test
    func fetchIntroductoryOffers_withEmptyPlanList_shouldReturnEmptyMapping() async {
        let mockRepo = MockIntroductoryOfferRepository(expectedMapping: [:])
        let sut = IntroductoryOfferUseCase(repository: mockRepo)
        
        let result = await sut.fetchIntroductoryOffers(for: [])
        
        #expect(result.isEmpty)
    }
    
    @Test
    func fetchIntroductoryOffers_withNoOffers_shouldReturnEmptyMapping() async {
        let plan1 = PlanEntity(productIdentifier: "plan1", type: .proI, subscriptionCycle: .yearly)
        let plan2 = PlanEntity(productIdentifier: "plan2", type: .proII, subscriptionCycle: .yearly)
        
        let mockRepo = MockIntroductoryOfferRepository(expectedMapping: [:])
        let sut = IntroductoryOfferUseCase(repository: mockRepo)
        
        let result = await sut.fetchIntroductoryOffers(for: [plan1, plan2])
        
        #expect(result.isEmpty)
    }
}

extension IntroductoryOfferEntity: Equatable {
    public static func == (lhs: IntroductoryOfferEntity, rhs: IntroductoryOfferEntity) -> Bool {
        lhs.price == rhs.price &&
        lhs.period.unit == rhs.period.unit &&
        lhs.period.value == rhs.period.value &&
        lhs.periodCount == rhs.periodCount
    }
}
