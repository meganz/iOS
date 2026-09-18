import FolderLink
import MEGADomain
import MEGADomainMock
import Testing

@Suite("FolderLinkSearchUseCase Tests")
struct FolderLinkSearchUseCaseTests {
    
    @Test("Returns repository root node")
    func returnsRepositoryRootNode() {
        // Given
        let expectedRoot = NodeEntity(handle: 12345)
        let repo = MockFolderLinkRepository(rootNode: expectedRoot.handle, nodesByHandle: [expectedRoot.handle: expectedRoot])
        let sut = FolderLinkSearchUseCase(folderLinkRepository: repo)
        
        // When
        let root = sut.rootFolderLink()
        
        // Then
        #expect(root == expectedRoot)
    }

    @Test("Returns nil when the repository has no node for the root handle")
    func returnsNilWhenRootNodeMissing() {
        // Given
        let repo = MockFolderLinkRepository(rootNode: 12345)
        let sut = FolderLinkSearchUseCase(folderLinkRepository: repo)

        // When
        let root = sut.rootFolderLink()

        // Then
        #expect(root == nil)
    }
}
