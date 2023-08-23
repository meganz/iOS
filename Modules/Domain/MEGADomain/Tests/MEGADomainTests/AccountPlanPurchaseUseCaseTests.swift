import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class AccountPlanPurchaseUseCaseTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
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
        [AccountPlanEntity(type: .proI, subscriptionCycle: .monthly),
         AccountPlanEntity(type: .proII, subscriptionCycle: .monthly),
         AccountPlanEntity(type: .proIII, subscriptionCycle: .monthly),
         AccountPlanEntity(type: .lite, subscriptionCycle: .monthly)]
    }
    
    private var yearlyPlans: [AccountPlanEntity] {
        [AccountPlanEntity(type: .proI, subscriptionCycle: .yearly),
         AccountPlanEntity(type: .proII, subscriptionCycle: .yearly),
         AccountPlanEntity(type: .proIII, subscriptionCycle: .yearly),
         AccountPlanEntity(type: .lite, subscriptionCycle: .yearly)]
    }
    
    private var allPlans: [AccountPlanEntity] {
        monthlyPlans + yearlyPlans
    }
    
    // MARK: - Restore purchase
    
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
    
    // MARK: - Purchase plan
    
    func testRegisterPurchaseDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountPlanPurchaseRepository()
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        await sut.registerPurchaseDelegate()
        XCTAssertTrue(mockRepo.registerPurchaseDelegateCalled == 1)
    }
    
    func testDeRegisterPurchaseDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountPlanPurchaseRepository()
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        await sut.deRegisterPurchaseDelegate()
        XCTAssertTrue(mockRepo.deRegisterPurchaseDelegateCalled == 1)
    }
    
    func testPurchasePublisher_successResultPublisher_shouldSendToPublisher() {
        let purchasePlanResultPublisher = PassthroughSubject<Result<Void, AccountPlanErrorEntity>, Never>()
        let mockRepo = MockAccountPlanPurchaseRepository(
            purchasePlanResultPublisher: purchasePlanResultPublisher.eraseToAnyPublisher()
        )
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        
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
        let mockRepo = MockAccountPlanPurchaseRepository(
            purchasePlanResultPublisher: purchasePlanResultPublisher.eraseToAnyPublisher()
        )
        let sut = AccountPlanPurchaseUseCase(repository: mockRepo)
        let expectedError = AccountPlanErrorEntity(errorCode: 1, errorMessage: "TestError")
        
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
