import FolderLink
import MEGADomain
import Testing

@Suite("FolderLinkQuickActionUseCase Tests")
struct FolderLinkQuickActionUseCaseTests {
    
    @Test("Returns false when node is missing")
    func returnsFalseWhenNodeIsMissing() {
        // Given
        let handle: HandleEntity = 100
        let repo = MockFolderLinkRepository(nodesByHandle: [:])
        let sut = FolderLinkQuickActionUseCase(folderLinkRepository: repo)
        
        // When
        let enabled = sut.shouldEnableQuickActions(for: handle)
        
        // Then
        #expect(enabled == false)
    }
    
    @Test("Returns false when node exists and is not decrypted")
    func returnsFalseWhenNodeExistsAndIsNotDecrypted() {
        // Given
        let handle: HandleEntity = 200
        let node = NodeEntity(handle: handle, isNodeKeyDecrypted: false)
        let repo = MockFolderLinkRepository(nodesByHandle: [handle: node])
        let sut = FolderLinkQuickActionUseCase(folderLinkRepository: repo)
        
        // When
        let enabled = sut.shouldEnableQuickActions(for: handle)
        
        // Then
        #expect(enabled == false)
    }
    
    @Test("Returns true when node exists and is decrypted")
    func returnsTrueWhenNodeExistsAndIsDecrypted() {
        // Given
        let handle: HandleEntity = 300
        let node = NodeEntity(handle: handle, isNodeKeyDecrypted: true)
        let repo = MockFolderLinkRepository(nodesByHandle: [handle: node])
        let sut = FolderLinkQuickActionUseCase(folderLinkRepository: repo)
        
        // When
        let enabled = sut.shouldEnableQuickActions(for: handle)
        
        // Then
        #expect(enabled == true)
    }
}
