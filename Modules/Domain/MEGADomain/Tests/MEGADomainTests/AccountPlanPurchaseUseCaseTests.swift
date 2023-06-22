import MEGADomain
import MEGADomainMock
import XCTest

final class AccountPlanPurchaseUseCaseTests: XCTestCase {

    func testAccountPlanProducts_monthly() async {
        let plans = monthlyPlans
        let mockRepo = MockAccountPlanPurchaseRepository(plans: plans)
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == plans)
    }
    
    func testAccountPlanProducts_yearly() async {
        let plans = yearlyPlans
        let mockRepo = MockAccountPlanPurchaseRepository(plans: plans)
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == plans)
    }
    
    func testAccountPlanProducts_monthlyAndYearly() async {
        let plans = allPlans
        let mockRepo = MockAccountPlanPurchaseRepository(plans: plans)
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == plans)
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
