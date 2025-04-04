@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class RubbishBinMenuDelegateHandlerTests: XCTestCase {
    
    class Harness {
        var sut: RubbishBinMenuDelegateHandler
        var receivedRestore: [NodeEntity] = []
        var receivedShowNodeInfo: [NodeEntity] = []
        var receivedShowNodeVersions: [NodeEntity] = []
        var receivedRemove: [NodeEntity] = []
        
        static let testNode: NodeEntity = NodeEntity(handle: 64)
        
        init() {
            var restore: (NodeEntity) -> Void = { _ in }
            var showNodeInfo: (NodeEntity) -> Void = { _ in }
            var showNodeVersions: (NodeEntity) -> Void = { _ in }
            var remove: (NodeEntity) -> Void = { _ in }
            
            sut = RubbishBinMenuDelegateHandler(
                restore: { restore($0) },
                showNodeInfo: { showNodeInfo($0) },
                showNodeVersions: { showNodeVersions($0) },
                remove: { remove($0) },
                nodeSource: .node { Self.testNode }
            )
            
            restore = {
                self.receivedRestore.append($0)
            }
            showNodeInfo = {
                self.receivedShowNodeInfo.append($0)
            }
            showNodeVersions = {
                self.receivedShowNodeVersions.append($0)
            }
            remove = {
                self.receivedRemove.append($0)
            }
        }
        
        func run(action: RubbishBinActionEntity) {
            sut.rubbishBinMenu(didSelect: action)
        }
    }
    
    func testRestoreAction_whenRan_passesInCorrectNodes() {
        let harness = Harness()
        harness.run(action: .restore)
        XCTAssertEqual(harness.receivedRestore, [Harness.testNode])
    }
    func testShowNodeInfoAction_whenRan_passesInCorrectNodes() {
        let harness = Harness()
        harness.run(action: .info)
        XCTAssertEqual(harness.receivedShowNodeInfo, [Harness.testNode])
    }
    func testShowNodeVersionsAction_whenRan_passesInCorrectNodes() {
        let harness = Harness()
        harness.run(action: .versions)
        XCTAssertEqual(harness.receivedShowNodeVersions, [Harness.testNode])
    }
    func testRemoveAction_whenRan_passesInCorrectNodes() {
        let harness = Harness()
        harness.run(action: .remove)
        XCTAssertEqual(harness.receivedRemove, [Harness.testNode])
    }
}
