@testable import MEGA
import MEGADomain
import XCTest

final class CloudDriveDownloadedNodesListenerTests: XCTestCase {
    func testDownloadedNodes_withEmptySubListener_shouldEmitNoValues() async {
        // given
        let sut = makeSUT(subListeners: [])
        let exp = expectation(description: "Wait for sequence to complete immediately")
        var outputCount = 0
        
        // when
        let task = Task {
            for await _ in sut.downloadedNodes {
                outputCount += 1
            }
            exp.fulfill()
        }
        
        // then
        await fulfillment(of: [exp], timeout: 0.5)
        XCTAssertEqual(outputCount, 0)
        task.cancel()
    }
    
    func testDownloadedNodes_withSingleSubListener_shouldEmitProperValues() async {
        // given
        let mockListener = MockDownloadedNodesListener()
        let inputHandles: [HandleEntity] = Array((0..<5))
        let downloadedNodes = inputHandles.compactMap { NodeEntity(handle: $0) }
        
        let sut = makeSUT(subListeners: [mockListener])
        let exp = expectation(description: "Wait for downloaded nodes")
        exp.expectedFulfillmentCount = downloadedNodes.count
        var outputHandles = [HandleEntity]()
        
        // when
        let task = Task {
            for await node in sut.downloadedNodes {
                outputHandles.append(node.handle)
                exp.fulfill()
            }
        }
        for node in downloadedNodes {
            mockListener.simulateDownloadedNode(node)
        }
        await fulfillment(of: [exp], timeout: 0.5)
        
        // then
        XCTAssertEqual(inputHandles, inputHandles)
        task.cancel()
    }
    
    func testDownloadedNodes_withTwoSubListeners_shouldEmitProperValues() async {
        // given
        let mockListener1 = MockDownloadedNodesListener()
        let mockListener2 = MockDownloadedNodesListener()
        let inputHandles: [HandleEntity] = Array((0..<10))
        let downloadedNodes = inputHandles.compactMap { NodeEntity(handle: $0) }
        
        let sut = makeSUT(subListeners: [mockListener1, mockListener2])
        let exp = expectation(description: "Wait for downloaded nodes")
        exp.expectedFulfillmentCount = downloadedNodes.count
        var outputHandles = [HandleEntity]()
        
        // when
        let task = Task {
            for await node in sut.downloadedNodes {
                outputHandles.append(node.handle)
                exp.fulfill()
            }
        }
        
        for (index, node) in downloadedNodes.enumerated() {
            // randomize the emission of sub listeners
            let listener = (index % 2 == 0) ? mockListener1 : mockListener2
            listener.simulateDownloadedNode(node)
        }
        
        // then
        await fulfillment(of: [exp], timeout: 0.5)
        XCTAssertEqual(outputHandles.sorted(), inputHandles)
        task.cancel()
    
    }
    
    private func makeSUT(subListeners: [any DownloadedNodesListening]) -> CloudDriveDownloadedNodesListener {
        CloudDriveDownloadedNodesListener(subListeners: subListeners)
    }
}
