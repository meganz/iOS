import XCTest
import MEGADomain
import MEGADomainMock

final class MyBackupsUseCaseTests: XCTestCase {
    let backupNodeEntity = NodeEntity(name: "backup", handle: 1, size: UInt64(1.3))
    
    private lazy var mockNodes: [NodeEntity] = {
        [NodeEntity(name: "other2", handle: 2),
         NodeEntity(name: "other3", handle: 3),
         NodeEntity(name: "other4", handle: 4)]
    }()
    
    func testMyBackups_IsMyBackupsNode() async {
        let myBackupsRepo = MockMyBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = MyBackupsUseCase(myBackupsRepository: myBackupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let isMyBackupsRootNode = await sut.isMyBackupsRootNode(backupNodeEntity)
        XCTAssertTrue(isMyBackupsRootNode)
        
        let isNotMyBackupsRootNode = await sut.isMyBackupsRootNode(NodeEntity(name: "other2"))
        XCTAssertFalse(isNotMyBackupsRootNode)
    }
    
    func testMyBackups_ContainsInboxRootNode() async {
        let myBackupsRepo = MockMyBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = MyBackupsUseCase(myBackupsRepository: myBackupsRepo, nodeRepository: MockNodeRepository.newRepo)
        var nodes = mockNodes
        let containsABackupNode_false = await sut.containsABackupNode(nodes)
        XCTAssertFalse(containsABackupNode_false)
        nodes.append(backupNodeEntity)
        let containsABackupNode_True = await sut.containsABackupNode(nodes)
        XCTAssertTrue(containsABackupNode_True)
    }
    
    func testMyBackups_BackupFolderSize() async {
        let myBackupsRepo = MockMyBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = MyBackupsUseCase(myBackupsRepository: myBackupsRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let backupSize = await sut.myBackupsRootNodeSize()
        
        XCTAssertEqual(backupSize, backupNodeEntity.size)
    }
    
    func testMyBackups_IsBackupDeviceFolder() {
        let myBackupsRepo = MockMyBackupsRepository(currentBackupNode: backupNodeEntity)
        let sut = MyBackupsUseCase(myBackupsRepository: myBackupsRepo, nodeRepository: MockNodeRepository.newRepo)
        let deviceFolderNode = NodeEntity(parentHandle: backupNodeEntity.handle, deviceId: "device")
        
        XCTAssertTrue(sut.isBackupDeviceFolder(deviceFolderNode))
    }
    
    func testMyBackups_IsBackupRootNodeEmpty() async throws {
        let myBackupsRepo_BackupEmpty = MockMyBackupsRepository(currentBackupNode: backupNodeEntity, isBackupRootNodeEmpty: true)
        let sut_backupEmpty = MyBackupsUseCase(myBackupsRepository: myBackupsRepo_BackupEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeEmpty = await sut_backupEmpty.isMyBackupsRootNodeEmpty()
        XCTAssertTrue(isBackupRootNodeEmpty)
        
        let myBackupsRepo_BackupNotEmpty = MockMyBackupsRepository(currentBackupNode: backupNodeEntity, isBackupRootNodeEmpty: false)
        let sut_backupNotEmpty = MyBackupsUseCase(myBackupsRepository: myBackupsRepo_BackupNotEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeNotEmpty = await sut_backupNotEmpty.isMyBackupsRootNodeEmpty()
        XCTAssertFalse(isBackupRootNodeNotEmpty)
    }
    
    func testMyBackups_IsInInbox() async {
        let myBackupsRepo = MockMyBackupsRepository(currentBackupNode: backupNodeEntity)
        let nodeRepo = MockNodeRepository(isNodeDescendant: true)
        let sut = MyBackupsUseCase(myBackupsRepository: myBackupsRepo, nodeRepository: nodeRepo)
        
        let isBackupsNode = await sut.isBackupNode(NodeEntity())
        XCTAssertTrue(isBackupsNode)
    }
}

