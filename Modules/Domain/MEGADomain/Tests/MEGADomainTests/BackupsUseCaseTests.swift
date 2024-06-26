import MEGADomain
import MEGADomainMock
import XCTest

final class BackupsUseCaseTests: XCTestCase {
    let backupNodeEntity = NodeEntity(name: "backup", handle: 1, size: UInt64(1.3))
    
    func testIsBackupsRootNode_validNode_returnsTrue() {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupsRootNode = sut.isBackupsRootNode(backupNodeEntity)
        XCTAssertTrue(isBackupsRootNode)
    }
    
    func testIsBackupsRootNode_invalidNode_returnsFalse() {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let isNotBackupsRootNode = sut.isBackupsRootNode(NodeEntity(name: "other2"))
        XCTAssertFalse(isNotBackupsRootNode)
    }
    
    func testIsBackupDeviceFolder_validDeviceFolder_returnsTrue() {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        let deviceFolderNode = NodeEntity(parentHandle: backupNodeEntity.handle, deviceId: "device")
        
        XCTAssertTrue(sut.isBackupDeviceFolder(deviceFolderNode))
    }
    
    func testIsBackupsRootNodeEmpty_backupRootNotEmpty_returnsTrue() async throws {
        let backupsRepo_BackupEmpty = MockBackupsRepository(currentBackupNode: backupNodeEntity, isBackupRootNodeEmpty: true)
        let sut_backupEmpty = BackupsUseCase(backupsRepository: backupsRepo_BackupEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeEmpty = await sut_backupEmpty.isBackupsRootNodeEmpty()
        XCTAssertTrue(isBackupRootNodeEmpty)
    }
    
    func testIsBackupsRootNodeEmpty_backupRootNotEmpty_returnsFalse() async throws {
        let backupsRepo_BackupNotEmpty = MockBackupsRepository(currentBackupNode: backupNodeEntity, isBackupRootNodeEmpty: false)
        let sut_backupNotEmpty = BackupsUseCase(backupsRepository: backupsRepo_BackupNotEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeNotEmpty = await sut_backupNotEmpty.isBackupsRootNodeEmpty()
        XCTAssertFalse(isBackupRootNodeNotEmpty)
    }
    
    func testIsBackupNode_validBackupNode_returnsTrue() {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity, isBackupNode: true)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupNode = sut.isBackupNode(NodeEntity())
        XCTAssertTrue(isBackupNode)
    }
    
    func testParentsForBackupHandle_ValidHandle_ReturnsParentsArray() async {
        let childNodeHandle: HandleEntity = 4
        let grandParentNode = NodeEntity(name: "Grand Parent", handle: 2, parentHandle: 1)
        let parentNode = NodeEntity(name: "Parent", handle: 3, parentHandle: 2)
        
        let sut = makeSUT(
            backupRootNode: NodeEntity(name: "Backups", handle: 1),
            parentNodes: [parentNode, grandParentNode],
            childNode: NodeEntity(name: "Child", handle: childNodeHandle, parentHandle: 3))
        
        let result = await sut.parentsForBackupHandle(childNodeHandle)
        let expectedNodes = [parentNode, grandParentNode]
        
        XCTAssertEqual(result, expectedNodes)
    }

    func testParentsForBackupHandle_invalidHandle_returnsNil() async {
        let sut = makeSUT(
            backupRootNode: NodeEntity(name: "Backups", handle: 1),
            childNode: nil)
        
        let result = await sut.parentsForBackupHandle(.invalid)
        
        XCTAssertNil(result)
    }
    
    func testParentsForBackupHandle_NoParentsBeforeBackupRoot_ReturnsEmptyArray() async throws {
        let sut = makeSUT(
            backupRootNode: NodeEntity(name: "Backups", handle: 1),
            childNode: NodeEntity(name: "Child", handle: 4, parentHandle: 3))
        
        let result = await sut.parentsForBackupHandle(.invalid)
        let unwrappedResult = try XCTUnwrap(result)
        XCTAssertTrue(unwrappedResult.isEmpty)
    }
    
    private func makeSUT(
        backupRootNode: NodeEntity,
        parentNodes: [NodeEntity] = [],
        childNode: NodeEntity?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BackupsUseCase<MockBackupsRepository, MockNodeRepository> {
        let nodeRepo = MockNodeRepository(node: childNode, parentNodes: parentNodes)
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupRootNode)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: nodeRepo)

        return sut
    }
}
