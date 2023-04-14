import XCTest
import MEGADomain
import MEGADomainMock

final class BackupsUseCaseTests: XCTestCase {
    let backupNodeEntity = NodeEntity(name: "backup", handle: 1, size: UInt64(1.3))
    
    private lazy var mockNodes: [NodeEntity] = {
        [NodeEntity(name: "other2", handle: 2), 
         NodeEntity(name: "other3", handle: 3),
         NodeEntity(name: "other4", handle: 4)]
    }()
    
    func testBackups_IsBackupsRootNode() {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupsRootNode = sut.isBackupsRootNode(backupNodeEntity)
        XCTAssertTrue(isBackupsRootNode)
        
        let isNotBackupsRootNode = sut.isBackupsRootNode(NodeEntity(name: "other2"))
        XCTAssertFalse(isNotBackupsRootNode)
    }
    
    func testBackups_BackupFolderSize() async {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let backupSize = await sut.backupsRootNodeSize()
        
        XCTAssertEqual(backupSize, backupNodeEntity.size)
    }
    
    func testBackups_IsBackupDeviceFolder() {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        let deviceFolderNode = NodeEntity(parentHandle: backupNodeEntity.handle, deviceId: "device")
        
        XCTAssertTrue(sut.isBackupDeviceFolder(deviceFolderNode))
    }
    
    func testBackups_IsBackupRootNodeEmpty() async throws {
        let backupsRepo_BackupEmpty = MockBackupsRepository(currentBackupNode: backupNodeEntity, isBackupRootNodeEmpty: true)
        let sut_backupEmpty = BackupsUseCase(backupsRepository: backupsRepo_BackupEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeEmpty = await sut_backupEmpty.isBackupsRootNodeEmpty()
        XCTAssertTrue(isBackupRootNodeEmpty)
        
        let backupsRepo_BackupNotEmpty = MockBackupsRepository(currentBackupNode: backupNodeEntity, isBackupRootNodeEmpty: false)
        let sut_backupNotEmpty = BackupsUseCase(backupsRepository: backupsRepo_BackupNotEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeNotEmpty = await sut_backupNotEmpty.isBackupsRootNodeEmpty()
        XCTAssertFalse(isBackupRootNodeNotEmpty)
    }
    
    func testBackups_IsInBackups() {
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupNodeEntity, isBackupNode: true)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupNode = sut.isBackupNode(NodeEntity())
        XCTAssertTrue(isBackupNode)
    }
}

