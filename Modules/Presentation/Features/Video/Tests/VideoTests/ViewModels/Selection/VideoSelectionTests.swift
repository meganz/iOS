import Combine
import MEGADomain
@testable import Video
import XCTest

final class VideoSelectionTests: XCTestCase {
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - EditMode
    
    func testEditMode_whenValueChanged_shouldSubscribeToValueChanged() {
        let sut = makeSUT()
        let exp = expectation(description: "Should change statuses")
        let statuses: [EditMode] = [.active, .inactive]
        var capturedEditModes = [EditMode]()
        sut.$editMode
            .dropFirst()
            .collect(2)
            .first()
            .sink {
                capturedEditModes.append(contentsOf: $0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.editMode = .active
        sut.editMode = .inactive
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(capturedEditModes, statuses)
    }
    
    func testEditMode_whenSetsToInactive_deselectAllVideos() {
        let sut = makeSUT()
        sut.allSelected = true
        
        sut.editMode = .inactive
        
        XCTAssertEqual(sut.allSelected, false)
    }
    
    // MARK: - isVideoSelected
    
    func testIsVideoSelected_whenSelectNodes_shouldSelectNodes() {
        let nodes = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2),
            NodeEntity(handle: 3)
        ]
        
        nodes.enumerated().forEach { (index, node) in
            let sut = makeSUT()
            
            sut.setSelectedVideos([node])
            
            XCTAssertTrue(sut.isVideoSelected(node), "Expect to select a node at index: \(index)")
        }
    }
    
    func testIsVideoSelected_whenSelectNodes_shouldNotSelectUnrelevantNode() {
        let sut = makeSUT()
        let nodes = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2),
            NodeEntity(handle: 3)
        ]
        
        nodes.forEach { sut.setSelectedVideos([$0]) }
        
        XCTAssertFalse(sut.isVideoSelected(NodeEntity(handle: 4)))
    }
    
    // MARK: - setSelectedVideos
    
    func testSetSelectedVideos_whenSelectNodes_shouldSelectVideos() {
        let nodes = [
            NodeEntity(handle: 11),
            NodeEntity(handle: 21),
            NodeEntity(handle: 31)
        ]
        let sut = makeSUT()
        
        sut.setSelectedVideos(nodes)
        
        XCTAssertEqual(sut.videos.count, 3)
    }
    
    // MARK: - allSelected
    
    func testAllSelected_whenSetsToFalse_shouldRemoveAllSelectedVideos() {
        let nodes = [
            NodeEntity(handle: 11),
            NodeEntity(handle: 21),
            NodeEntity(handle: 31)
        ]
        let sut = makeSUT()
        sut.setSelectedVideos(nodes)
        
        sut.allSelected = false
        
        XCTAssertTrue(sut.videos.isEmpty)
    }
    
    // MARK: - toggleSelection
    
    func testToggleSelection_whenHasSingleNodeNoSelectedNode_shouldToggleNodeToSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let nodes = [
            firstNode
        ]
        
        nodes.forEach { sut.toggleSelection(for: $0) }
        
        XCTAssertTrue(sut.isVideoSelected(firstNode))
        XCTAssertEqual(sut.videos.count, nodes.count)
    }
    
    func testToggleSelection_whenHasMoreThanOneNodeNoSelectedNode_shouldToggleFirstNodeOnlyToSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let secondNode = NodeEntity(handle: 2)
        let nodes = [
            firstNode,
            secondNode
        ]
        
        sut.toggleSelection(for: firstNode)
        
        XCTAssertTrue(sut.isVideoSelected(firstNode))
        XCTAssertFalse(sut.isVideoSelected(secondNode))
        XCTAssertEqual(sut.videos.count, nodes.count - 1)
    }
    
    func testToggleSelection_whenHasMoreThanOneNodeNoSelectedNode_shouldToggleLastNodeOnlyToSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let secondNode = NodeEntity(handle: 2)
        let nodes = [
            firstNode,
            secondNode
        ]
        
        sut.toggleSelection(for: secondNode)
        
        XCTAssertFalse(sut.isVideoSelected(firstNode))
        XCTAssertTrue(sut.isVideoSelected(secondNode))
        XCTAssertEqual(sut.videos.count, nodes.count - 1)
    }
    
    func testToggleSelection_whenHasMoreThanOneNodeNoSelectedNode_shouldSetAllNodesToSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let secondNode = NodeEntity(handle: 2)
        let nodes = [
            firstNode,
            secondNode
        ]
        
        nodes.forEach { sut.toggleSelection(for: $0) }
        
        XCTAssertTrue(sut.isVideoSelected(firstNode))
        XCTAssertTrue(sut.isVideoSelected(secondNode))
        XCTAssertEqual(sut.videos.count, nodes.count)
    }
    
    func testToggleSelection_whenOneNodeIsSelected_shouldToggleNodeToNotSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let nodes = [
            firstNode
        ]
        sut.setSelectedVideos(nodes)
        
        nodes.forEach { sut.toggleSelection(for: $0) }
        
        XCTAssertFalse(sut.isVideoSelected(firstNode))
    }
    
    func testToggleSelection_whenMoreThanOneNodeIsSelected_shouldToggleFirstNodeOnlyToNotSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let secondNode = NodeEntity(handle: 2)
        let nodes = [
            firstNode,
            secondNode
        ]
        sut.setSelectedVideos(nodes)
        
        sut.toggleSelection(for: firstNode)
        
        XCTAssertFalse(sut.isVideoSelected(firstNode))
        XCTAssertTrue(sut.isVideoSelected(secondNode))
        XCTAssertEqual(sut.videos.count, 1)
    }
    
    func testToggleSelection_whenMoreThanOneNodeIsSelected_shouldToggleLastNodeOnlyToNotSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let secondNode = NodeEntity(handle: 2)
        let nodes = [
            firstNode,
            secondNode
        ]
        sut.setSelectedVideos(nodes)
        
        sut.toggleSelection(for: secondNode)
        
        XCTAssertTrue(sut.isVideoSelected(firstNode))
        XCTAssertFalse(sut.isVideoSelected(secondNode))
        XCTAssertEqual(sut.videos.count, 1)
    }
    
    func testToggleSelection_whenHasMoreThanOneNodeSelectedNode_shouldSetAllNodesToNotSelected() {
        let sut = makeSUT()
        let firstNode = NodeEntity(handle: 1)
        let secondNode = NodeEntity(handle: 2)
        let nodes = [
            firstNode,
            secondNode
        ]
        sut.setSelectedVideos(nodes)
        
        nodes.forEach { sut.toggleSelection(for: $0) }
        
        XCTAssertFalse(sut.isVideoSelected(firstNode))
        XCTAssertFalse(sut.isVideoSelected(secondNode))
        XCTAssertTrue(sut.videos.isEmpty)
    }
    
    // MARK: - isVideoSelectedPublisher
    
    func testIsVideoSelectedPublisher_whenToggledOnce_shouldSelectNode() {
        let node1 = NodeEntity(handle: 1)
        let sut = makeSUT()
        
        let exp = expectation(description: "wait for isVideoSelectedPublisher subscription")
        exp.expectedFulfillmentCount = 2
        var receivedValues: [Bool] = []
        sut.isVideoSelectedPublisher(for: node1)
            .sink {
                receivedValues.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.toggleSelection(for: node1)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedValues, [false, true])
    }
    
    func testIsVideoSelectedPublisher_whenToggledTwice_shouldUnselectNode() {
        let node1 = NodeEntity(handle: 1)
        let sut = makeSUT()
        
        let exp = expectation(description: "wait for isVideoSelectedPublisher subscription")
        exp.expectedFulfillmentCount = 3
        var receivedValues: [Bool] = []
        sut.isVideoSelectedPublisher(for: node1)
            .sink {
                receivedValues.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.toggleSelection(for: node1)
        sut.toggleSelection(for: node1)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedValues, [false, true, false])
    }
    
    func testIsVideoSelectedPublisher_whenhasMoreThanOneNode_shouldChangeSelectedStateOfToggledNodeOnly() {
        let node1 = NodeEntity(handle: 1)
        let node2 = NodeEntity(handle: 2)
        let sut = makeSUT()
        
        let exp = expectation(description: "wait for node 1 isVideoSelectedPublisher subscription")
        exp.expectedFulfillmentCount = 3
        var receivedNode1Values: [Bool] = []
        sut.isVideoSelectedPublisher(for: node1)
            .sink {
                receivedNode1Values.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        let exp2 = expectation(description: "wait for node 1 isVideoSelectedPublisher subscription")
        var receivedNode2Values: [Bool] = []
        sut.isVideoSelectedPublisher(for: node2)
            .sink {
                receivedNode2Values.append($0)
                exp2.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.toggleSelection(for: node1)
        sut.toggleSelection(for: node1)
        wait(for: [exp, exp2], timeout: 0.5)
        
        XCTAssertEqual(receivedNode1Values, [false, true, false])
        XCTAssertEqual(receivedNode2Values, [false])
    }
    
    // MARK: - onTappedCheckMark
    
    func testOnTappedCheckMark_whenIsSelectionDisabled_shouldNotToggleSelection() {
        let node1 = NodeEntity(handle: 1)
        let sut = makeSUT()
        sut.isSelectionDisabled = true
        
        sut.onTappedCheckMark(for: node1)
        
        XCTAssertTrue(sut.videos.isEmpty)
    }
    
    func testOnTappedCheckMark_whenIsNotInEditingState_shouldNotToggleSelection() {
        let node1 = NodeEntity(handle: 1)
        let sut = makeSUT()
        sut.editMode = .inactive
        
        sut.onTappedCheckMark(for: node1)
        
        XCTAssertTrue(sut.videos.isEmpty)
    }
    
    func testOnTappedCheckMark_whenIsSelectionEnabledButNotInEditingMode_shouldNotToggleSelection() {
        let node1 = NodeEntity(handle: 1)
        let sut = makeSUT()
        sut.isSelectionDisabled = false
        sut.editMode = .inactive
        
        sut.onTappedCheckMark(for: node1)
        
        XCTAssertTrue(sut.videos.isEmpty)
    }
    
    func testOnTappedCheckMark_whenEligibleForEditingMode_shouldToggleSelection() {
        let node1 = NodeEntity(handle: 1)
        let sut = makeSUT()
        sut.isSelectionDisabled = false
        sut.editMode = .active
        
        sut.onTappedCheckMark(for: node1)
        
        XCTAssertEqual(sut.videos.count, 1)
        XCTAssertEqual(sut.videos.first?.key, node1.handle)
        XCTAssertEqual(sut.videos.first?.value, node1)
    }
    
    func testOnTappedCheckMark_whenEligibleForEditingModeAndTappedTwice_shouldToggleSelection() {
        let node1 = NodeEntity(handle: 1)
        let sut = makeSUT()
        sut.isSelectionDisabled = false
        sut.editMode = .active
        
        sut.onTappedCheckMark(for: node1)
        sut.onTappedCheckMark(for: node1)
        
        XCTAssertTrue(sut.videos.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VideoSelection {
        let sut = VideoSelection()
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
