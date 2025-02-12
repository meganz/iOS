import MEGADomain
import MEGADomainMock
import Testing

@Suite("BackupsUseCaseTests")
struct BackupsUseCaseTests {
    private let backupNodeEntity = NodeEntity(name: "backup", handle: 1)
    
    @Test("Is backups node for valid node returns true")
    func isBackupsRootNode_validNode_returnsTrue() {
        let sut = makeSUT(backupRootNode: backupNodeEntity)
        
        let isBackupsRootNode = sut.isBackupsRootNode(backupNodeEntity)
        #expect(isBackupsRootNode)
    }
    
    @Test("Is backups node for invalid node returns false")
    func isBackupsRootNode_invalidNode_returnsFalse() {
        let sut = makeSUT(backupRootNode: backupNodeEntity)
        
        let isBackupsRootNode = sut.isBackupsRootNode(NodeEntity(name: "other2"))
        #expect(!isBackupsRootNode)
    }
    
    @Test("Is backups node for valid backup node returns true")
    func isBackupNode_validBackupNode_returnsTrue() {
        let sut = makeSUT(backupRootNode: backupNodeEntity, isBackupNode: true)
        
        let isBackupNode = sut.isBackupNode(NodeEntity())
        #expect(isBackupNode)
    }
    
    @Test("Parents for backup handle with valid handle returns parents array")
    func parentsForBackupHandle_validHandle_returnsParentsArray() async {
        let childNodeHandle: HandleEntity = 4
        let grandParentNode = NodeEntity(name: "Grand Parent", handle: 2, parentHandle: 1)
        let parentNode = NodeEntity(name: "Parent", handle: 3, parentHandle: 2)
        
        let sut = makeSUT(
            backupRootNode: backupNodeEntity,
            parentNodes: [parentNode, grandParentNode],
            childNode: NodeEntity(name: "Child", handle: childNodeHandle, parentHandle: 3))
        
        let result = await sut.parentsForBackupHandle(childNodeHandle)
        let expectedNodes = [parentNode, grandParentNode]
        
        #expect(result == expectedNodes)
    }

    @Test("Parents for backup handle with invalid handle returns nil")
    func parentsForBackupHandle_invalidHandle_returnsNil() async {
        let sut = makeSUT(
            backupRootNode: backupNodeEntity)
        
        let result = await sut.parentsForBackupHandle(.invalid)
        
        #expect(result == nil)
    }
    
    @Test("Parents for backup handle with no parents before backup root returns an empty array")
    func parentsForBackupHandle_noParentsBeforeBackupRoot_returnsEmptyArray() async throws {
        let sut = makeSUT(
            backupRootNode: backupNodeEntity,
            childNode: NodeEntity(name: "Child", handle: 4, parentHandle: 3))
        
        let result = await sut.parentsForBackupHandle(.invalid)
        let unwrappedResult = try #require(result)
        #expect(unwrappedResult.isEmpty)
    }
    
    private func makeSUT(
        backupRootNode: NodeEntity,
        parentNodes: [NodeEntity] = [],
        childNode: NodeEntity? = nil,
        isBackupNode: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BackupsUseCase<MockBackupsRepository, MockNodeRepository> {
        let nodeRepo = MockNodeRepository(node: childNode, parentNodes: parentNodes)
        let backupsRepo = MockBackupsRepository(currentBackupNode: backupRootNode, isBackupNode: isBackupNode)
        let sut = BackupsUseCase(backupsRepository: backupsRepo, nodeRepository: nodeRepo)

        return sut
    }
}
