import Combine
import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class NodeTransferRepositoryTest: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }
    
    func testRegisterTransferDelegate_delegateShouldExist() async {
        let mockSdk = MockSdk()
        let repo = NodeTransferRepository(sdk: mockSdk, sharedFolderSdk: mockSdk)
        await repo.registerMEGATransferDelegate()
        
        XCTAssertTrue(mockSdk.hasTransferDelegate)
    }
    
    func testRegisterSharedFolderTransferDelegate_delegateShouldExist() async {
        let mockSdk = MockSdk()
        let repo = NodeTransferRepository(sdk: mockSdk, sharedFolderSdk: mockSdk)
        await repo.registerMEGASharedFolderTransferDelegate()
        
        XCTAssertTrue(mockSdk.hasTransferDelegate)
    }

    func testDeRegisterTransferDelegate_delegateShouldNotExist() async {
        let mockSdk = MockSdk()
        mockSdk.hasTransferDelegate = true
        
        let repo = NodeTransferRepository(sdk: mockSdk, sharedFolderSdk: mockSdk)
        await repo.deRegisterMEGATransferDelegate()
        
        XCTAssertFalse(mockSdk.hasTransferDelegate)
    }
    
    func testDeRegisterSharedFolderTransferDelegate_delegateShouldNotExist() async {
        let mockSdk = MockSdk()
        mockSdk.hasTransferDelegate = true
        
        let repo = NodeTransferRepository(sdk: mockSdk, sharedFolderSdk: mockSdk)
        await repo.deRegisterMEGASharedFolderTransferDelegate()
        
        XCTAssertFalse(mockSdk.hasTransferDelegate)
    }
    
    func testTransferResultPublisher_onTransferFinish_whenApiOk_sendsSuccessResult() {
        let apiOk = MockError(errorType: .apiOk)
        let mockSdk = MockSdk()
        let sut = NodeTransferRepository(sdk: mockSdk, sharedFolderSdk: mockSdk)
        
        let exp = expectation(description: "Should receive success with TransferEntity")
        let megaTransfer = MockTransfer(type: .download, nodeHandle: 1, parentHandle: 2)
        sut.transferResultPublisher
            .sink { request in
                switch request {
                case .success(let result):
                    let transferEntity = megaTransfer.toTransferEntity()
                    XCTAssertEqual(result.type, transferEntity.type)
                    XCTAssertEqual(result.nodeHandle, transferEntity.nodeHandle)
                    XCTAssertEqual(result.parentHandle, transferEntity.parentHandle)
                case .failure:
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onTransferFinish(mockSdk, transfer: megaTransfer, error: apiOk)
        wait(for: [exp], timeout: 1)
    }
    
    func testTransferResultPublisher_onTransferFinish_withError_sendsError() {
        let apiError = MockError.failingError
        let mockSdk = MockSdk()
        let sut = NodeTransferRepository(sdk: mockSdk, sharedFolderSdk: mockSdk)
        
        let exp = expectation(description: "Should receive error TransferErrorEntity")
        sut.transferResultPublisher
            .sink { request in
                switch request {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    XCTAssertEqual(error, apiError.toTransferErrorEntity())
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.onTransferFinish(mockSdk, transfer: MockTransfer(), error: apiError)
        wait(for: [exp], timeout: 1)
    }
}
