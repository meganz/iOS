import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeTransferUseCaseTests: XCTestCase {

    private var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    func testRegisterTransferDelegate_addDelegateShouldBeCalled() async {
        let mockRepo = MockNodeTransferRepository()
        let sut = NodeTransferUseCase(repo: mockRepo)
        
        await sut.registerMEGATransferDelegate()
        
        XCTAssertTrue(mockRepo.registerMEGATransferDelegateCalled == 1)
    }
    
    func testRegisterSharedFolderTransferDelegate_addDelegateShouldBeCalled() async {
        let mockRepo = MockNodeTransferRepository()
        let sut = NodeTransferUseCase(repo: mockRepo)
        
        await sut.registerMEGASharedFolderTransferDelegate()
        
        XCTAssertTrue(mockRepo.registerMEGASharedFolderTransferDelegateCalled == 1)
    }
    
    func testDeRegisterTransferDelegate_removeDelegateShouldBeCalled() async {
        let mockRepo = MockNodeTransferRepository()
        let sut = NodeTransferUseCase(repo: mockRepo)
        
        await sut.deRegisterMEGATransferDelegate()
        
        XCTAssertTrue(mockRepo.deRegisterMEGATransferDelegateCalled == 1)
    }

    func testDeRegisterSharedFolderTransferDelegate_removeDelegateShouldBeCalled() async {
        let mockRepo = MockNodeTransferRepository()
        let sut = NodeTransferUseCase(repo: mockRepo)
        
        await sut.deRegisterMEGASharedFolderTransferDelegate()
        
        XCTAssertTrue(mockRepo.deRegisterMEGASharedFolderTransferDelegateCalled == 1)
    }

    func testTransferResultPublisher_shouldReturnSuccessResult() {
        let transferResultPublisher = PassthroughSubject<Result<TransferEntity, TransferErrorEntity>, Never>()
        let mockRepo = MockNodeTransferRepository(
            transferResultPublisher: transferResultPublisher.eraseToAnyPublisher()
        )
        
        let sut = NodeTransferUseCase(repo: mockRepo)
        let successResult = TransferEntity(type: .download, nodeHandle: 1)
        let exp = expectation(description: "Should receive success AccountRequestEntity")
        sut.transferResultPublisher()
            .sink { request in
                switch request {
                case .success(let result):
                    XCTAssertEqual(result.type, successResult.type)
                    XCTAssertEqual(result.nodeHandle, successResult.nodeHandle)
                case .failure:
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        transferResultPublisher.send(.success(successResult))
        wait(for: [exp], timeout: 1.0)
    }
    
    func testTransferResultPublisher_shouldReturnFailedResult() {
        let transferResultPublisher = PassthroughSubject<Result<TransferEntity, TransferErrorEntity>, Never>()
        let mockRepo = MockNodeTransferRepository(
            transferResultPublisher: transferResultPublisher.eraseToAnyPublisher()
        )
        
        let sut = NodeTransferUseCase(repo: mockRepo)
        let failedResult = TransferErrorEntity.allCases.randomElement() ?? .download
        let exp = expectation(description: "Should receive failed TransferErrorEntity")
        sut.transferResultPublisher()
            .sink { request in
                switch request {
                case .success:
                    XCTFail("Successful request is not expected.")
                case .failure(let error):
                    XCTAssertEqual(error, failedResult)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        transferResultPublisher.send(.failure(failedResult))
        wait(for: [exp], timeout: 1.0)
    }
}
