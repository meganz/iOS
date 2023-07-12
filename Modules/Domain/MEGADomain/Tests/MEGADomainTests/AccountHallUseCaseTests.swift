import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class AccountHallUseCaseTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testContactRequestsCount_onViewAppear_shouldBeEqual() async {
        let contactsRequestsExpectedCount = 1
        let sut = AccountHallUseCase(repository: MockAccountRepository(contactsRequestsCount: contactsRequestsExpectedCount))
        let contactsCount = await sut.incomingContactsRequestsCount()
        
        XCTAssertEqual(contactsCount, contactsRequestsExpectedCount)
    }
    
    func testUnseenUserAlertsCount_onViewAppear_shouldBeEqual() async {
        let unSeenUserAlertsExpectedCount: UInt = 2
        let sut = AccountHallUseCase(repository: MockAccountRepository(unseenUserAlertsCount: unSeenUserAlertsExpectedCount))
        let unSeenUserAlertsCount = await sut.relevantUnseenUserAlertsCount()
        
        XCTAssertEqual(unSeenUserAlertsCount, unSeenUserAlertsExpectedCount)
    }
    
    func test_isMasterBusinessAccount_shouldBeTrue() {
        let sut = AccountHallUseCase(repository: MockAccountRepository(isMasterBusinessAccount: true))
        XCTAssertTrue(sut.isMasterBusinessAccount)
    }
    
    func test_isMasterBusinessAccount_shouldBeFalse() {
        let sut = AccountHallUseCase(repository: MockAccountRepository(isMasterBusinessAccount: false))
        XCTAssertFalse(sut.isMasterBusinessAccount)
    }
    
    func testRequestResultPublisher_shouldReturnSuccessResult() {
        let requestResultPublisher = PassthroughSubject<Result<AccountRequestEntity, Error>, Never>()
        let mockRepo = MockAccountRepository(
            requestResultPublisher: requestResultPublisher.eraseToAnyPublisher()
        )
        let sut = AccountHallUseCase(repository: mockRepo)
        
        let successResult = AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil, accountDetails: nil)
        let exp = expectation(description: "Should receive success AccountRequestEntity")
        sut.requestResultPublisher()
            .sink { request in
                switch request {
                case .success(let result):
                    XCTAssertEqual(result, successResult)
                case .failure:
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        requestResultPublisher.send(.success(successResult))
        wait(for: [exp], timeout: 1.0)
    }
    
    func testContactRequestPublisher_shouldReturnContactRequestEntityList() {
        let contactRequestPublisher = PassthroughSubject<[ContactRequestEntity], Never>()
        let mockRepo = MockAccountRepository(
            contactRequestPublisher: contactRequestPublisher.eraseToAnyPublisher()
        )
        let sut = AccountHallUseCase(repository: mockRepo)
        
        let expectedList = [ContactRequestEntity.random]
        let exp = expectation(description: "Should receive ContactRequestEntity list")
        sut.contactRequestPublisher()
            .sink { list in
                XCTAssertEqual(list, expectedList)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        contactRequestPublisher.send(expectedList)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testUserAlertPublisher_shouldReturnUserAlertEntityList() {
        let userAlertUpdatePublisher = PassthroughSubject<[UserAlertEntity], Never>()
        let mockRepo = MockAccountRepository(
            userAlertUpdatePublisher: userAlertUpdatePublisher.eraseToAnyPublisher()
        )
        let sut = AccountHallUseCase(repository: mockRepo)
        
        let expectedList = [UserAlertEntity.random]
        let exp = expectation(description: "Should receive UserAlertEntity list")
        sut.userAlertUpdatePublisher()
            .sink { list in
                XCTAssertEqual(list, expectedList)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        userAlertUpdatePublisher.send(expectedList)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRegisterMEGARequestDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountRepository()
        let sut = AccountHallUseCase(repository: mockRepo)
        await sut.registerMEGARequestDelegate()
        XCTAssertTrue(mockRepo.registerMEGARequestDelegateCalled == 1)
    }
    
    func testDeRegisterMEGARequestDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountRepository()
        let sut = AccountHallUseCase(repository: mockRepo)
        await sut.deRegisterMEGARequestDelegate()
        XCTAssertTrue(mockRepo.deRegisterMEGARequestDelegateCalled == 1)
    }
    
    func testRegisterMEGAGlobalDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountRepository()
        let sut = AccountHallUseCase(repository: mockRepo)
        await sut.registerMEGAGlobalDelegate()
        XCTAssertTrue(mockRepo.registerMEGAGlobalDelegateCalled == 1)
    }
    
    func testDeRegisterMEGAGlobalDelegateCalled_shouldReturnTrue() async {
        let mockRepo = MockAccountRepository()
        let sut = AccountHallUseCase(repository: mockRepo)
        await sut.deRegisterMEGAGlobalDelegate()
        XCTAssertTrue(mockRepo.deRegisterMEGAGlobalDelegateCalled == 1)
    }
    
}
