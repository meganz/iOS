@testable import MEGA
import MEGADomain
import XCTest

final class CloudDriveDownloadedNodesListenerTests: XCTestCase {
    func testDownloadedNodes_withEmptySubListener_shouldEmitNoValues() async {
        // given
        let sut = makeSUT(subListeners: [])
        let exp = expectation(description: "Wait for sequence to complete immediately")
        
        // when
        let task = Task {
            var outputCount = 0
            for await _ in sut.downloadedNodes {
                outputCount += 1
            }
            exp.fulfill()
            return outputCount
        }
        
        // then
        await fulfillment(of: [exp], timeout: 0.5)
        let outputCount = await task.value
        XCTAssertEqual(outputCount, 0)
        task.cancel()
    }
    
    func testDownloadedNodes_withTwoSubListeners_shouldEmitProperValues() async {
        // given
        let nodes1 = [1, 2, 3].map { NodeEntity(handle: $0) }
        let nodes2 = [4, 5, 6].map { NodeEntity(handle: $0) }
        let mockListener1 = MockDownloadedNodesListener(downloadedNodes: nodes1.async.eraseToAnyAsyncSequence())
        let mockListener2 = MockDownloadedNodesListener(downloadedNodes: nodes2.async.eraseToAnyAsyncSequence())
        let inputHandles: Set<HandleEntity> = [1, 2, 3, 4, 5, 6]
        
        let sut = makeSUT(subListeners: [mockListener1, mockListener2])
        
        // when
        var outputHandles: Set<HandleEntity> = []
        for await node in sut.downloadedNodes {
            outputHandles.insert(node.handle)
        }
        
        XCTAssertEqual(outputHandles, inputHandles)
    }
    
    private func makeSUT(subListeners: [any DownloadedNodesListening]) -> CloudDriveDownloadedNodesListener {
        CloudDriveDownloadedNodesListener(subListeners: subListeners)
    }
}
