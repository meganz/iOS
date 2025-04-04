@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class QuickActionsMenuDelegateHandlerTests: XCTestCase {
    
    class Harness {
        var sut: QuickActionsMenuDelegateHandler
        var receivedSharedFolderNodes: [[NodeEntity]] = []
        var receivedInfoNodes: [NodeEntity] = []
        var receivedManageShareNodes: [NodeEntity] = []
        var receivedNodesToDownload: [[NodeEntity]] = []
        var receivedNodesToGetLink: [[NodeEntity]] = []
        var receivedNodesToCopy: [NodeEntity] = []
        var receivedNodesToRemoveLink: [[NodeEntity]] = []
        var receivedNodesToRemoveSharing: [NodeEntity] = []
        var receivedNodesToRename: [NodeEntity] = []
        var receivedNodesToLeaveSharing: [NodeEntity] = []
        
        static let testNode: NodeEntity = NodeEntity(handle: 64)
        
        init() {
            var showNodeInfo: (NodeEntity) -> Void = { _ in }
            var manageShare: (NodeEntity) -> Void = { _ in }
            var shareFolders: ([NodeEntity]) -> Void = { _ in }
            var downloadNodes: ([NodeEntity]) -> Void = { _ in }
            var presentGetLink: ([NodeEntity]) -> Void = { _ in }
            var copyNode: (NodeEntity) -> Void = { _ in }
            var removeLink: ([NodeEntity]) -> Void = { _ in }
            var removeSharing: (NodeEntity) -> Void = { _ in }
            var rename: (NodeEntity) -> Void = { _ in }
            var leaveSharing: (NodeEntity) -> Void = { _ in }
            
            sut = QuickActionsMenuDelegateHandler(
                showNodeInfo: { showNodeInfo($0) },
                manageShare: { manageShare($0) },
                shareFolders: { shareFolders($0) }, 
                download: { downloadNodes($0) },
                presentGetLink: { presentGetLink($0) },
                copy: { copyNode($0) },
                removeLink: { removeLink($0) },
                removeSharing: { removeSharing($0) },
                rename: { rename($0) },
                leaveSharing: { leaveSharing($0) },
                nodeSource: .node { Self.testNode }
            )
            shareFolders = {
                self.receivedSharedFolderNodes.append($0)
            }
            showNodeInfo = {
                self.receivedInfoNodes.append($0)
            }
            manageShare = {
                self.receivedManageShareNodes.append($0)
            }
            downloadNodes = {
                self.receivedNodesToDownload.append($0)
            }
            presentGetLink = {
                self.receivedNodesToGetLink.append($0)
            }
            copyNode = {
                self.receivedNodesToCopy.append($0)
            }
            removeLink = {
                self.receivedNodesToRemoveLink.append($0)
            }
            removeSharing = {
                self.receivedNodesToRemoveSharing.append($0)
            }
            rename = {
                self.receivedNodesToRename.append($0)
            }
            leaveSharing = {
                self.receivedNodesToLeaveSharing.append($0)
            }
        }
        
        func run(action: QuickActionEntity) {
            sut.quickActionsMenu(
                didSelect: action,
                needToRefreshMenu: false
            )
        }
    }
    
    func testNodeInfo_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .info)
        XCTAssertEqual(harness.receivedInfoNodes, [Harness.testNode])
    }
    
    func testManageFolderInfo_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .manageFolder)
        XCTAssertEqual(harness.receivedManageShareNodes, [Harness.testNode])
    }
    
    func testShareFolders_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .shareFolder)
        XCTAssertEqual(harness.receivedSharedFolderNodes, [[Harness.testNode]])
    }
    
    func testDownloadFolders_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .download)
        XCTAssertEqual(harness.receivedNodesToDownload, [[Harness.testNode]])
    }
    
    func testShareLink_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .shareLink)
        XCTAssertEqual(harness.receivedNodesToGetLink, [[Harness.testNode]])
    }
    
    func testManageLinkPassesCorrectNodes_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .manageLink)
        XCTAssertEqual(harness.receivedNodesToGetLink, [[Harness.testNode]])
    }
    
    func testCopyNode_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .copy)
        XCTAssertEqual(harness.receivedNodesToCopy, [Harness.testNode])
    }
    
    func testRemoveLink_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .removeLink)
        XCTAssertEqual(harness.receivedNodesToRemoveLink, [[Harness.testNode]])
    }
    
    func testRemoveSharing_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .removeSharing)
        XCTAssertEqual(harness.receivedNodesToRemoveSharing, [Harness.testNode])
    }
}
