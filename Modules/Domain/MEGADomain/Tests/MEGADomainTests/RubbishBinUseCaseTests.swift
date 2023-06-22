import MEGADomain
import MEGADomainMock
import XCTest

final class RubbishBinUseCaseTests: XCTestCase {
    func testRubbishBin_existsSyncDebris() {
        let syncDebrisNode = NodeEntity(name: "SyncDebris")
        let sut_exists = RubbishBinUseCase(rubbishBinRepository: MockRubbishBinRepository(syncDebrisNode: syncDebrisNode))
        let sut_not_exists = RubbishBinUseCase(rubbishBinRepository: MockRubbishBinRepository())
        
        let isSyncDebrisRootNode = sut_exists.isSyncDebrisNode(syncDebrisNode)
        XCTAssertTrue(isSyncDebrisRootNode)
        let isNotSyncDebrisRootNode = sut_not_exists.isSyncDebrisNode(NodeEntity())
        XCTAssertFalse(isNotSyncDebrisRootNode)
    }
    
    func testRubbishBin_isSyncDebrisChild() {
        let syncDebrisChild = NodeEntity(name: "childNode1", handle: 1)
        let sut = RubbishBinUseCase(rubbishBinRepository:
                                            MockRubbishBinRepository(syncDebrisChildNodes: [syncDebrisChild]))
        let isSyncDebrisChild = sut.isSyncDebrisNode(syncDebrisChild)
        XCTAssertTrue(isSyncDebrisChild)
        let isNotSyncDebrisChild = sut.isSyncDebrisNode(NodeEntity())
        XCTAssertFalse(isNotSyncDebrisChild)
    }
}
