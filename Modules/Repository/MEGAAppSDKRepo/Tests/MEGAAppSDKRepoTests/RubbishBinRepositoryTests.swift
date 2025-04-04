import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASwift
import XCTest

final class RubbishBinRepositoryTests: XCTestCase {
    private var sdk: MockSdk!
    private var repo: RubbishBinRepository!
    
    private var rubbishBinNode = MockNode(handle: 1, name: "RubbishBin", nodeType: .folder, nodePath: "//bin")
    private var rubbishBinChildNode = MockNode(handle: 5, name: "OtherNode", nodeType: .folder, parentHandle: 1, nodePath: "//bin")
    private lazy var syncDebrisNodes = [MockNode(handle: 2, name: "SyncDebris", nodeType: .folder, parentHandle: 1, nodePath: "//bin/SyncDebris"),
                                        MockNode(handle: 3, name: "SyncDebris", nodeType: .folder, parentHandle: 1, nodePath: "//bin/SyncDebris"),
                                        MockNode(handle: 4, name: "SyncDebris", nodeType: .folder, parentHandle: 1, nodePath: "//bin/SyncDebris"),
                                        MockNode(handle: 6, name: "SyncDebris1Child", nodeType: .folder, parentHandle: 2, nodePath: "//bin/SyncDebris"),
                                        MockNode(handle: 7, name: "SyncDebris2Child", nodeType: .folder, parentHandle: 3, nodePath: "//bin/SyncDebris"),
                                        MockNode(handle: 8, name: "SyncDebris3Child", nodeType: .folder, parentHandle: 4, nodePath: "//bin/SyncDebris"),
                                        MockNode(handle: 9, name: "SyncDebris3Child", nodeType: .folder, parentHandle: 8, nodePath: "//bin/SyncDebris"),
                                        MockNode(handle: 10, name: "SyncDebris3Child", nodeType: .folder, parentHandle: 9, nodePath: "//bin/SyncDebris")]
    
    override func setUpWithError() throws {
        var testNodesArray = syncDebrisNodes
        testNodesArray.append(contentsOf: [rubbishBinNode, rubbishBinChildNode])
        
        sdk = MockSdk(nodes: testNodesArray,
                      syncDebrisNodes: syncDebrisNodes,
                      rubbishBinNode: rubbishBinNode)
        
        repo = RubbishBinRepository(sdk: sdk)
    }
    
    func test_isSyncDebrisNode() async throws {
        XCTAssertTrue(syncDebrisNodes.allSatisfy {
            self.repo.isSyncDebrisNode($0.toNodeEntity())
        })
        
        let isNotSyncDebrisNode = repo.isSyncDebrisNode(rubbishBinChildNode.toNodeEntity())
        XCTAssertFalse(isNotSyncDebrisNode)
    }
}
