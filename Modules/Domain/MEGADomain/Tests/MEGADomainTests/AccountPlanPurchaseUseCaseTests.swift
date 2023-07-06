import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class AccountPlanPurchaseUseCaseTests: XCTestCase {

    // MARK: - Plans
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
    
    // MARK: - Publishers
    private var subscriptions = Set<AnyCancellable>()
    
    func testRegisterRestoreDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountPlanPurchaseRepository()
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        await sut.registerRestoreDelegate()
        XCTAssertTrue(mockRepo.registerRestoreDelegateCalled == 1)
    }
    
    func testDeRegisterRestoreDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountPlanPurchaseRepository()
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        await sut.deRegisterRestoreDelegate()
        XCTAssertTrue(mockRepo.deRegisterRestoreDelegateCalled == 1)
    }
    
    func testRestorePublisher_successfulRestorePublisher_shouldEmitToPublisher() {
        let successfulRestorePublisher = PassthroughSubject<Void, Never>()
        let mockRepo = MockAccountPlanPurchaseRepository(
            successfulRestorePublisher: successfulRestorePublisher.eraseToAnyPublisher()
        )
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        
        let exp = expectation(description: "Should receive signal from successfulRestorePublisher")
        sut.successfulRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        successfulRestorePublisher.send()
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRestorePublisher_incompleteRestorePublisher_shouldSendToPublisher() {
        let incompleteRestorePublisher = PassthroughSubject<Void, Never>()
        let mockRepo = MockAccountPlanPurchaseRepository(
            incompleteRestorePublisher: incompleteRestorePublisher.eraseToAnyPublisher()
        )
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        
        let exp = expectation(description: "Should receive signal from incompleteRestorePublisher")
        sut.incompleteRestorePublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        incompleteRestorePublisher.send()
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRestorePublisher_failedRestorePublisher_shouldSendToPublisher() {
        let failedRestorePublisher = PassthroughSubject<AccountPlanErrorEntity, Never>()
        let mockRepo = MockAccountPlanPurchaseRepository(
            failedRestorePublisher: failedRestorePublisher.eraseToAnyPublisher()
        )
        let exp = expectation(description: "Should receive signal from failedRestorePublisher")
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "Test Error")
        sut.failedRestorePublisher
            .sink { errorEntity in
                XCTAssertEqual(errorEntity.errorCode, expectedError.errorCode)
                XCTAssertEqual(errorEntity.errorMessage, expectedError.errorMessage)
                exp.fulfill()
            }.store(in: &subscriptions)
        failedRestorePublisher.send(expectedError)
        wait(for: [exp], timeout: 1)
    }
}
