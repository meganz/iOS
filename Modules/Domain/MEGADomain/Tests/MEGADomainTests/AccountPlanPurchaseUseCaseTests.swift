import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class AccountPlanPurchaseUseCaseTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - Helpers
    private func makeSUT(
        plans: [PlanEntity] = [],
        successfulRestorePublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        incompleteRestorePublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        failedRestorePublisher: AnyPublisher<AccountPlanErrorEntity, Never> = Empty().eraseToAnyPublisher(),
        purchasePlanResultPublisher: AnyPublisher<Result<Void, AccountPlanErrorEntity>, Never> = Empty().eraseToAnyPublisher()
    ) -> (sut: AccountPlanPurchaseUseCase<MockAccountPlanPurchaseRepository>, repository: MockAccountPlanPurchaseRepository) {
        let mockRepo = MockAccountPlanPurchaseRepository(
            plans: plans,
            successfulRestorePublisher: successfulRestorePublisher,
            incompleteRestorePublisher: incompleteRestorePublisher,
            failedRestorePublisher: failedRestorePublisher,
            purchasePlanResultPublisher: purchasePlanResultPublisher
        )
        return (AccountPlanPurchaseUseCase(repository: mockRepo), mockRepo)
    }
    
    private var monthlyPlans: [PlanEntity] {
        [PlanEntity(type: .proI, subscriptionCycle: .monthly),
         PlanEntity(type: .proII, subscriptionCycle: .monthly),
         PlanEntity(type: .proIII, subscriptionCycle: .monthly),
         PlanEntity(type: .lite, subscriptionCycle: .monthly)]
    }
    
    private var yearlyPlans: [PlanEntity] {
        [PlanEntity(type: .proI, subscriptionCycle: .yearly),
         PlanEntity(type: .proII, subscriptionCycle: .yearly),
         PlanEntity(type: .proIII, subscriptionCycle: .yearly),
         PlanEntity(type: .lite, subscriptionCycle: .yearly)]
    }
    
    private var allPlans: [PlanEntity] {
        monthlyPlans + yearlyPlans
    }
    
    // MARK: - Plans
    func testAccountPlanProducts_monthly() async {
        let (sut, _) = makeSUT(plans: monthlyPlans)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == monthlyPlans)
    }
    
    func testAccountPlanProducts_yearly() async {
        let (sut, _) = makeSUT(plans: yearlyPlans)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == yearlyPlans)
    }
    
    func testAccountPlanProducts_monthlyAndYearly() async {
        let (sut, _) = makeSUT(plans: allPlans)
        let products = await sut.accountPlanProducts()
        XCTAssertTrue(products == allPlans)
    }
    
    // MARK: - Restore purchase
    
    func testRegisterRestoreDelegateCalled_shouldReturnTrue() async {
        let (sut, mockRepo) = makeSUT()
        await sut.registerRestoreDelegate()
        XCTAssertTrue(mockRepo.registerRestoreDelegateCalled == 1)
    }
    
    func testDeRegisterRestoreDelegateCalled_shouldReturnTrue() async {
        let (sut, mockRepo) = makeSUT()
        await sut.deRegisterRestoreDelegate()
        XCTAssertTrue(mockRepo.deRegisterRestoreDelegateCalled == 1)
    }
    
    func testRestorePublisher_successfulRestorePublisher_shouldEmitToPublisher() {
        let successfulRestorePublisher = PassthroughSubject<Void, Never>()
        let (sut, _) = makeSUT(successfulRestorePublisher: successfulRestorePublisher.eraseToAnyPublisher())
        
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
        let (sut, _) = makeSUT(incompleteRestorePublisher: incompleteRestorePublisher.eraseToAnyPublisher())
        
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
        let exp = expectation(description: "Should receive signal from failedRestorePublisher")
        let (sut, _) = makeSUT(failedRestorePublisher: failedRestorePublisher.eraseToAnyPublisher())
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
    
    // MARK: - Purchase plan
    
    func testRegisterPurchaseDelegateCalled_shouldReturnTrue() async {
        let (sut, mockRepo) = makeSUT()
        await sut.registerPurchaseDelegate()
        XCTAssertTrue(mockRepo.registerPurchaseDelegateCalled == 1)
    }
    
    func testDeRegisterPurchaseDelegateCalled_shouldReturnTrue() async {
        let (sut, mockRepo) = makeSUT()
        await sut.deRegisterPurchaseDelegate()
        XCTAssertTrue(mockRepo.deRegisterPurchaseDelegateCalled == 1)
    }
    
    func testPurchasePublisher_successResultPublisher_shouldSendToPublisher() {
        let purchasePlanResultPublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
        let (sut, _) = makeSUT(purchasePlanResultPublisher: purchasePlanResultPublisher.eraseToAnyPublisher())
        
        let exp = expectation(description: "Should receive success result from purchasePlanResultPublisher")
        sut.purchasePlanResultPublisher()
            .sink { result in
                if case .failure = result {
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        purchasePlanResultPublisher.send(.success(()))
        wait(for: [exp], timeout: 1.0)
    }
    
    func testPurchasePublisher_failedResultPublisher_shouldSendToPublisher() {
        let purchasePlanResultPublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "TestError")
        let (sut, _) = makeSUT(purchasePlanResultPublisher: purchasePlanResultPublisher.eraseToAnyPublisher())
        
        let exp = expectation(description: "Should receive success result from purchasePlanResultPublisher")
        sut.purchasePlanResultPublisher()
            .sink { result in
                switch result {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error.errorCode, expectedError.errorCode)
                    XCTAssertEqual(error.errorMessage, expectedError.errorMessage)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        purchasePlanResultPublisher.send(.failure(expectedError))
        wait(for: [exp], timeout: 1.0)
    }
}
