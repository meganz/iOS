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
        var receivedNodesToShareOrManageLink: [[NodeEntity]] = []
        var receivedNodesToCopy: [NodeEntity] = []
        var receivedNodesToRemoveLink: [[NodeEntity]] = []
        var receivedNodesToRemoveSharing: [NodeEntity] = []
        var receivedNodesToRename: [NodeEntity] = []
        var receivedNodesToLeaveSharing: [NodeEntity] = []
        var receivedNodesToHide: [[NodeEntity]] = []
        var receivedNodesToUnhide: [[NodeEntity]] = []
        
        static let testNode: NodeEntity = NodeEntity(handle: 64)
        private let (stream, continuation) = AsyncStream.makeStream(of: [NodeEntity].self)
        
        init() {
            var showNodeInfo: (NodeEntity) -> Void = { _ in }
            var manageShare: (NodeEntity) -> Void = { _ in }
            var shareFolders: ([NodeEntity]) -> Void = { _ in }
            var downloadNodes: ([NodeEntity]) -> Void = { _ in }
            var shareOrManageLink: ([NodeEntity]) -> Void = { _ in }
            var copyNode: (NodeEntity) -> Void = { _ in }
            var removeLink: ([NodeEntity]) -> Void = { _ in }
            var removeSharing: (NodeEntity) -> Void = { _ in }
            var rename: (NodeEntity) -> Void = { _ in }
            var leaveSharing: (NodeEntity) -> Void = { _ in }
            var hideNodes: ([NodeEntity]) -> Void = { _ in }
            var unhideNodes: ([NodeEntity]) -> Void = { _ in }
            
            let nodeSource = NodeSource.node({ Self.testNode })
            
            sut = QuickActionsMenuDelegateHandler(
                showNodeInfo: { showNodeInfo($0) },
                manageShare: { manageShare($0) },
                shareFolders: { shareFolders($0) },
                download: { downloadNodes($0) },
                shareOrManageLink: { shareOrManageLink($0) },
                copy: { copyNode($0) },
                removeLink: { removeLink($0) },
                removeSharing: { removeSharing($0) },
                rename: { rename($0) },
                leaveSharing: { leaveSharing($0) },
                hide: { hideNodes($0) },
                unhide: { unhideNodes($0) },
                nodeSource: nodeSource,
                nodeSourceUpdatesListener: NewCloudDriveNodeSourceUpdatesListener(
                    originalNodeSource: nodeSource,
                    nodeUpdatesProvider: MockNodeUpdatesProvider(
                        nodeUpdates: stream.eraseToAnyAsyncSequence()
                    )
                )
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
            shareOrManageLink = {
                self.receivedNodesToShareOrManageLink.append($0)
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
            hideNodes = {
                self.receivedNodesToHide.append($0)
            }
            unhideNodes = {
                self.receivedNodesToUnhide.append($0)
            }
        }
        
        func run(action: QuickActionEntity) {
            sut.quickActionsMenu(
                didSelect: action,
                needToRefreshMenu: false
            )
        }
        
        func nodeUpdates(_ nodes: [NodeEntity]) {
            continuation.yield(nodes)
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
        XCTAssertEqual(harness.receivedNodesToShareOrManageLink, [[Harness.testNode]])
    }
    
    func testManageLinkPassesCorrectNodes_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .manageLink)
        XCTAssertEqual(harness.receivedNodesToShareOrManageLink, [[Harness.testNode]])
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
    
    func testHide_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .hide)
        XCTAssertEqual(harness.receivedNodesToHide, [[Harness.testNode]])
    }
    
    func testUnhide_whenRan_callsClosureWithCorrectNodes() {
        let harness = Harness()
        harness.run(action: .unhide)
        XCTAssertEqual(harness.receivedNodesToUnhide, [[Harness.testNode]])
    }
    
    func testNodeSourceUpdate_whenRan_callsClosureWithCorrectNodes() {
        let updatedNode = NodeEntity(
            handle: Harness.testNode.handle,
            isMarkedSensitive: true)
        let harness = Harness()
        harness.nodeUpdates([updatedNode])
        
        harness.run(action: .unhide)
        
        XCTAssertEqual(harness.receivedNodesToUnhide, [[updatedNode]])
    }
}
