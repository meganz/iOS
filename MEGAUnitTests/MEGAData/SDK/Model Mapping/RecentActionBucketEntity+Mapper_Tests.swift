
import XCTest
@testable import MEGA

final class RecentActionBucketEntity_Mapper_Tests: XCTestCase {
    
    func testRecentActionBucketInit_withZeroNodesInTheList() {
        let date = Date()
        let recentActionBucketEntity = RecentActionBucketEntity(with: MockRecentActionBucket(timestamp: date))
        XCTAssertTrue(recentActionBucketEntity.date == date)
        XCTAssertTrue(recentActionBucketEntity.userEmail == "name@email.com")
        XCTAssertTrue(recentActionBucketEntity.parentHandle == 1)
        XCTAssertTrue(recentActionBucketEntity.isUpdate == false)
        XCTAssertTrue(recentActionBucketEntity.isMedia == false)
        XCTAssertTrue(recentActionBucketEntity.nodes.count == 0)
    }
    
    func testRecentActionBucketInit_withMultipleNodesInTheList() {
        let date = Date()
        let nodes = [MockNode(nodeHandle: 1), MockNode(nodeHandle: 2), MockNode(nodeHandle: 3), MockNode(nodeHandle: 4)]
        let nodeList = MockNodeList(nodes: nodes)
        let recentBucketObject = MockRecentActionBucket(timestamp: date, nodeList: nodeList)
        let recentActionBucketEntity = RecentActionBucketEntity(with: recentBucketObject)
        XCTAssertTrue(recentActionBucketEntity.nodes.count == nodes.count)
    }
    
    func testRecentActionBucketInit_whenMediaIsTrue() {
        let recentActionBucketEntity = RecentActionBucketEntity(with: MockRecentActionBucket(isMedia: true))
        XCTAssertTrue(recentActionBucketEntity.isMedia == true)
    }
    
    func testRecentActionBucketInit_whenIsUpdateIsTrue() {
        let recentActionBucketEntity = RecentActionBucketEntity(with: MockRecentActionBucket(isUpdate: true))
        XCTAssertTrue(recentActionBucketEntity.isUpdate == true)
    }
}

final fileprivate class MockRecentActionBucket: MEGARecentActionBucket {
    private let _timestamp: Date
    private let _email: String
    private let _parentHandle: MEGAHandle
    private let _isUpdate: Bool
    private let _isMedia: Bool
    private let _nodeList: MEGANodeList
    
    init(
        timestamp: Date = Date(),
        email: String = "name@email.com",
        parentHandle: MEGAHandle = 1,
        isUpdate: Bool = false,
        isMedia: Bool = false,
        nodeList: MEGANodeList = MockNodeList()
    ) {
        _timestamp = timestamp
        _email = email
        _parentHandle = parentHandle
        _isUpdate = isUpdate
        _isMedia = isMedia
        _nodeList = nodeList
        super.init()
    }
    
    override var timestamp: Date! {
        _timestamp
    }
    
    override var userEmail: String! {
        _email
    }
    
    override var parentHandle: UInt64 {
        _parentHandle
    }
    
    override var isUpdate: Bool {
        _isUpdate
    }
    
    override var isMedia: Bool {
        _isMedia
    }
    
    override var nodesList: MEGANodeList! {
        _nodeList
    }
}

final fileprivate class MockNodeList: MEGANodeList {
    private let nodes: [MEGANode]
    
    init(nodes: [MEGANode] = []) {
        self.nodes = nodes
        super.init()
    }
    
    override var size: NSNumber! {
        NSNumber(integerLiteral: nodes.count)
    }
    
    override func node(at index: Int) -> MEGANode! {
        nodes[index]
    }
}

final fileprivate class MockNode: MEGANode {
    private let _nodeHandle: MEGAHandle
    private let nodeChanges: MEGANodeChangeType
    
    init(nodeHandle: MEGAHandle = 1, nodeChanges: MEGANodeChangeType = .removed) {
        _nodeHandle = nodeHandle
        self.nodeChanges = nodeChanges
        super.init()
    }
    
    override func getChanges() -> MEGANodeChangeType {
        nodeChanges
    }
}
