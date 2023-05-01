import XCTest
import MEGADomain
import MEGADomainMock

final class AccountPlanPurchaseUseCaseTests: XCTestCase {

    func testAccountPlanProducts_monthly() {
        let plans = monthlyPlans
        let mockRepo = MockAccountPlanPurchaseRepository(plans: plans)
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        
        XCTAssertTrue(sut.accountPlanProducts() == plans)
    }
    
    func testAccountPlanProducts_yearly() {
        let plans = yearlyPlans
        let mockRepo = MockAccountPlanPurchaseRepository(plans: plans)
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        
        XCTAssertTrue(sut.accountPlanProducts() == plans)
    }
    
    func testAccountPlanProducts_monthlyAndYearly() {
        let plans = allPlans
        let mockRepo = MockAccountPlanPurchaseRepository(plans: plans)
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        
        XCTAssertTrue(sut.accountPlanProducts() == plans)
    }
    
    private var monthlyPlans: [AccountPlanEntity] {
        [AccountPlanEntity(type: .proI, term: .monthly),
         AccountPlanEntity(type: .proII, term: .monthly),
         AccountPlanEntity(type: .proIII, term: .monthly),
         AccountPlanEntity(type: .lite, term: .monthly)]
    }
    
    private var yearlyPlans: [AccountPlanEntity] {
        [AccountPlanEntity(type: .proI, term: .yearly),
         AccountPlanEntity(type: .proII, term: .yearly),
         AccountPlanEntity(type: .proIII, term: .yearly),
         AccountPlanEntity(type: .lite, term: .yearly)]
    }
    
    private var allPlans: [AccountPlanEntity] {
        monthlyPlans + yearlyPlans
    }
}
