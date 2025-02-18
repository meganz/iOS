import Combine
import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class AudioPlayerRepositoryTests: XCTestCase {
    
    private var subscriptions = [AnyCancellable]()
    
    func testInit_doesNotRegisterMEGADelegate() {
        let (_, sdk) = makeSUT()
        
        XCTAssertEqual(sdk.addMEGADelegateCallCount, 0)
    }
    
    func testRegisterMEGADelegate_calledSetDelegate() async {
        let (sut, sdk) = makeSUT()
        
        await sut.registerMEGADelegate()
        
        XCTAssertEqual(sdk.addMEGADelegateCallCount, 1)
        
        await sut.unregisterMEGADelegate()
    }
    
    func testUnregisterMEGADelegate_shouldNotCalledRemoveDelegate() async {
        let (sut, sdk) = makeSUT()
        
        await sut.unregisterMEGADelegate()
        
        XCTAssertEqual(sdk.removeMEGADelegateCallCount, 1)
    }
    
    func testOnNodesUpdate_whenInvoked_sendsUpdate() {
        let (sut, sdk) = makeSUT()
        let sampleNodes = [MockNode(handle: 1)]
        let sampleNodeList = MockNodeList(nodes: sampleNodes)
        var receivedEntities: [NodeEntity]?
        sut.reloadItemPublisher
            .sink(receiveValue: { nodeEntities in receivedEntities = nodeEntities })
            .store(in: &subscriptions)
        
        sut.onNodesUpdate(sdk, nodeList: sampleNodeList)
        
        XCTAssertEqual(receivedEntities, sampleNodeList.toNodeEntities())
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: AudioPlayerRepository, sdk: MockSdk) {
        let sdk = MockSdk()
        let sut = AudioPlayerRepository(sdk: sdk)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        trackForMemoryLeaks(on: sdk, file: file, line: line)
        return (sut, sdk)
    }

}
