import XCTest
import MEGADomain
import MEGADomainMock

final class RubbishBinUseCaseTests: XCTestCase {
    func testRubbishBin_existsSyncDebris() async {
        let syncDebrisNode = NodeEntity(name: "SyncDebris")
        let sut_exists = RubbishBinUseCase(rubbishBinRepository: MockRubbishBinRepository(syncDebrisNode: syncDebrisNode))
        let sut_not_exists = RubbishBinUseCase(rubbishBinRepository: MockRubbishBinRepository())
        
        let isSyncDebrisRootNode = await sut_exists.isSyncDebrisNode(syncDebrisNode)
        XCTAssertTrue(isSyncDebrisRootNode)
        let isNotSyncDebrisRootNode = await sut_not_exists.isSyncDebrisNode(NodeEntity())
        XCTAssertFalse(isNotSyncDebrisRootNode)
    }
    
    func testRubbishBin_isSyncDebrisChild() async {
        let syncDebrisChild = NodeEntity(name: "childNode1", handle: 1)
        let sut = RubbishBinUseCase(rubbishBinRepository:
                                            MockRubbishBinRepository(syncDebrisChildNodes:[syncDebrisChild]))
        let isSyncDebrisChild = await sut.isSyncDebrisNode(syncDebrisChild)
        XCTAssertTrue(isSyncDebrisChild)
        let isNotSyncDebrisChild = await sut.isSyncDebrisNode(NodeEntity())
        XCTAssertFalse(isNotSyncDebrisChild)
    }
}
