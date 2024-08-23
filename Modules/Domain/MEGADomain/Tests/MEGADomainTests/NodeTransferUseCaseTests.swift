import MEGADomain
import MEGADomainMock
import XCTest

final class NodeTransferUseCaseTests: XCTestCase {
    private var nodeTransferRepository: MockNodeTransferRepository!
    private var sut: NodeTransferUseCase<MockNodeTransferRepository>!
    
    override func setUp() {
        super.setUp()
        nodeTransferRepository = MockNodeTransferRepository()
        sut = NodeTransferUseCase(repo: nodeTransferRepository)
    }
    
    override func tearDown() {
        nodeTransferRepository = nil
        sut = nil
        super.tearDown()
    }
    
    func testNodeTransferCompletionUpdates_whenAccessMultipleTimes_shouldReceiveElementsIndependently() async {
        let firstExpectation = expectation(description: "First node transfer completion monitoring task")
        let secondExpectation = expectation(description: "Second node transfer completion monitoring task")
        
        let firstTask = startMonitoringNodeTransferCompletionUpdates(firstExpectation)
        
        nodeTransferRepository.yield(TransferEntity(nodeHandle: 1))
        
        let secondTask = startMonitoringNodeTransferCompletionUpdates(secondExpectation)
        
        nodeTransferRepository.yield(TransferEntity(nodeHandle: 2))
        
        firstTask.cancel()
        
        nodeTransferRepository.yield(TransferEntity(nodeHandle: 3))
        
        secondTask.cancel()
        
        await fulfillment(of: [firstExpectation, secondExpectation], timeout: 1)
        
        await XCTAsyncAssertNoThrow(await firstTask.value.map(\.nodeHandle) == [1, 2])
        await XCTAsyncAssertNoThrow(await secondTask.value.map(\.nodeHandle) == [2, 3])
    }
    
    private func startMonitoringNodeTransferCompletionUpdates(_ expectationToFulfill: XCTestExpectation) -> Task<[TransferEntity], Never> {
        Task { [sut] in
            guard let sut else { return [] }
            var transfers: [TransferEntity] = []
            
            for await transfer in sut.nodeTransferCompletionUpdates {
                transfers.append(transfer)
            }
            expectationToFulfill.fulfill()
            return transfers
        }
    }
}
