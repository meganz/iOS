import XCTest
import MEGADomain
import MEGADomainMock

final class InboxUseCaseTests: XCTestCase {
    let inboxNodeEntity = NodeEntity(name: "inbox", handle: 1)
    let backupNodeEntity = NodeEntity(name: "backup", handle: 2, size: UInt64(1.3))
    
    private lazy var mockNodes: [NodeEntity] = {
        [NodeEntity(name: "other2", handle: 2),
         NodeEntity(name: "other3", handle: 3),
         NodeEntity(name: "other4", handle: 4)]
    }()
    
    func testInbox_IsInboxNode() {
        let nodeInboxRepo = MockInboxRepository(currentInboxNode: inboxNodeEntity)
        
        // Node repository without any inbox node ancestor
        let nodeRepo = MockNodeRepository(isNodeDescendant: false)
        let sut = InboxUseCase(inboxRepository: nodeInboxRepo, nodeRepository: nodeRepo)
        
        // Node repository with some inbox node ancestor
        let nodeRepo2 = MockNodeRepository(isNodeDescendant: true)
        let sut2 = InboxUseCase(inboxRepository: nodeInboxRepo, nodeRepository: nodeRepo2)
        
        // True because inboxNodeEntity is the inbox root node, the main ancestor
        XCTAssertTrue(sut.isInboxNode(inboxNodeEntity))
        // True because nodeRepo2 has some inbox node ancestor
        XCTAssertTrue(sut2.isInboxNode(backupNodeEntity))
        XCTAssertFalse(sut.isInboxNode(backupNodeEntity))
    }
    
    func testNodeInbox_ContainsInboxRootNode() {
        let nodeInboxRepo = MockInboxRepository(currentInboxNode: inboxNodeEntity)
        let sut = InboxUseCase(inboxRepository: nodeInboxRepo, nodeRepository: MockNodeRepository.newRepo)
        var nodes = mockNodes
        
        XCTAssertFalse(sut.containsAnyInboxNode(nodes))
        nodes.append(inboxNodeEntity)
        XCTAssertTrue(sut.containsAnyInboxNode(nodes))
    }
    
    func testNodeInbox_IsInboxRootNode() {
        let nodeInboxRepo = MockInboxRepository(currentInboxNode: inboxNodeEntity)
        let sut = InboxUseCase(inboxRepository: nodeInboxRepo, nodeRepository: MockNodeRepository.newRepo)

        XCTAssertTrue(sut.isInboxRootNode(inboxNodeEntity))
        XCTAssertFalse(sut.isInboxRootNode(backupNodeEntity))
    }
    
    func testInbox_BackupFolderSize() async throws {
        let nodeInboxRepo = MockInboxRepository(currentBackupNode: backupNodeEntity)
        let sut = InboxUseCase(inboxRepository: nodeInboxRepo, nodeRepository: MockNodeRepository.newRepo)
        
        let backupSize = try await sut.backupRootNodeSize()
        
        XCTAssertEqual(backupSize, backupNodeEntity.size)
    }
    
    func testInbox_IsBackupDeviceFolder() {
        let nodeInboxRepo = MockInboxRepository(currentBackupNode: backupNodeEntity)
        let sut = InboxUseCase(inboxRepository: nodeInboxRepo, nodeRepository: MockNodeRepository.newRepo)
        let deviceFolderNode = NodeEntity(parentHandle: backupNodeEntity.handle, deviceId: "device")
        
        XCTAssertTrue(sut.isBackupDeviceFolder(deviceFolderNode))
    }
    
    func testInbox_IsBackupRootNodeEmpty() async throws {
        let nodeInboxRepo_BackupEmpty = MockInboxRepository(isBackupRootNodeEmpty: true)
        let sut_backupEmpty = InboxUseCase(inboxRepository: nodeInboxRepo_BackupEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeEmpty = await sut_backupEmpty.isBackupRootNodeEmpty()
        XCTAssertTrue(isBackupRootNodeEmpty)
        
        let nodeInboxRepo_BackupNotEmpty = MockInboxRepository(isBackupRootNodeEmpty: false)
        let sut_backupNotEmpty = InboxUseCase(inboxRepository: nodeInboxRepo_BackupNotEmpty, nodeRepository: MockNodeRepository.newRepo)
        
        let isBackupRootNodeNotEmpty = await sut_backupNotEmpty.isBackupRootNodeEmpty()
        XCTAssertFalse(isBackupRootNodeNotEmpty)
    }
    
    func testInbox_IsInInbox() {
        let nodeInboxRepo = MockInboxRepository(currentInboxNode: inboxNodeEntity)
        let nodeRepo = MockNodeRepository(isNodeDescendant: true)
        let sut = InboxUseCase(inboxRepository: nodeInboxRepo, nodeRepository: nodeRepo)
        
        XCTAssertTrue(sut.isInInbox(NodeEntity()))
    }
}
