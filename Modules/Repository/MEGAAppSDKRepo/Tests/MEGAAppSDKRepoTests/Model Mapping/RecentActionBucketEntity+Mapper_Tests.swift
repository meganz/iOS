import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

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
        let nodes = [MockNode(handle: 1), MockNode(handle: 2), MockNode(handle: 3), MockNode(handle: 4)]
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
