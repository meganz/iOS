@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class CloudDriveViewControllerMediaCheckerModeTests: XCTestCase {

    func testMakeVisualMediaChecker_whenNodeIsNilForContainsExclusivelyMedia_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsExclusivelyMedia
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { nil }, nodeUseCase: MockNodeDataUseCase()
        )()
        XCTAssertFalse(expectedResult)
    }

    func testMakeVisualMediaChecker_whenChildNodeIsNilForContainsExclusivelyMedia_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsExclusivelyMedia
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { NodeEntity() }, nodeUseCase: MockNodeDataUseCase()
        )()
        XCTAssertFalse(expectedResult)
    }

    func testMakeVisualMediaChecker_whenNodeIsNilForContainsSomeMedia_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsSomeMedia
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { nil }, nodeUseCase: MockNodeDataUseCase()
        )()
        XCTAssertFalse(expectedResult)
    }

    func testMakeVisualMediaChecker_whenChildNodeIsNilForContainsSomeMedia_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsSomeMedia
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { NodeEntity() }, nodeUseCase: MockNodeDataUseCase()
        )()
        XCTAssertFalse(expectedResult)
    }

    func testMakeVisualMediaChecker_whenContainsExclusivelyMedia_shouldReturnTrue() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsExclusivelyMedia
        let nodeList = NodeListEntity(nodesCount: 3, nodeAt: { _ in NodeEntity(name: "test.jpg") })
        let nodeUseCase = MockNodeDataUseCase(nodeListEntity: nodeList)
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { NodeEntity() }, nodeUseCase: nodeUseCase
        )()
        XCTAssertTrue(expectedResult)
    }

    func testMakeVisualMediaChecker_whenDoesNotContainsExclusivelyMedia_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsExclusivelyMedia
        let nodeList = NodeListEntity(nodesCount: 3, nodeAt: { _ in NodeEntity(name: "test.txt") })
        let nodeUseCase = MockNodeDataUseCase(nodeListEntity: nodeList)
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { NodeEntity() }, nodeUseCase: nodeUseCase
        )()
        XCTAssertFalse(expectedResult)
    }

    func testMakeVisualMediaChecker_whenDoesNotContainsExclusivelyMedia_shouldReturnTrue() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsSomeMedia
        let nodeList = NodeListEntity(
            nodesCount: 3,
            nodeAt: { index in
                NodeEntity(
                    name: index == 1 ? "test.jpg" : "test.txt"
                )
            }
        )
        let nodeUseCase = MockNodeDataUseCase(nodeListEntity: nodeList)
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { NodeEntity() }, nodeUseCase: nodeUseCase
        )()
        XCTAssertTrue(expectedResult)
    }

    func testMakeVisualMediaChecker_whenDoesNotContainsSomeMedia_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsSomeMedia
        let nodeList = NodeListEntity(nodesCount: 3, nodeAt: { _ in NodeEntity(name: "test.txt") })
        let nodeUseCase = MockNodeDataUseCase(nodeListEntity: nodeList)
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .node { NodeEntity() }, nodeUseCase: nodeUseCase
        )()
        XCTAssertFalse(expectedResult)
    }

    func testMakeVisualMediaChecker_whenContainsSomeMediaInRecentActionBucket_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsSomeMedia
        let nodeList = NodeListEntity(nodesCount: 3, nodeAt: { _ in NodeEntity(name: "test.jpg") })
        let nodeUseCase = MockNodeDataUseCase(nodeListEntity: nodeList)
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .mockRecentActionBucketEmpty, nodeUseCase: nodeUseCase
        )()
        XCTAssertFalse(expectedResult)
    }

    func testMakeVisualMediaChecker_whenContainsExclusivelyMediaInRecentActionBucket_shouldReturnFalse() async {
        let mode = CloudDriveViewControllerMediaCheckerMode.containsExclusivelyMedia
        let nodeList = NodeListEntity(nodesCount: 3, nodeAt: { _ in NodeEntity(name: "test.jpg") })
        let nodeUseCase = MockNodeDataUseCase(nodeListEntity: nodeList)
        let expectedResult = mode.makeVisualMediaPresenceChecker(
            nodeSource: .mockRecentActionBucketEmpty, nodeUseCase: nodeUseCase
        )()
        XCTAssertFalse(expectedResult)
    }
}
