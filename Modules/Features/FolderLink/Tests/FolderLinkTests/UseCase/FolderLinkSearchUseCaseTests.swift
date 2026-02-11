import FolderLink
import MEGADomain
import Testing

@Suite("FolderLinkSearchUseCase Tests")
struct FolderLinkSearchUseCaseTests {
    
    @Test("Returns repository root handle")
    func returnsRepositoryRootHandle() {
        // Given
        let expectedRoot: HandleEntity = 12345
        let repo = MockFolderLinkRepository(rootNode: expectedRoot)
        let sut = FolderLinkSearchUseCase(folderLinkRepository: repo)
        
        // When
        let root = sut.rootFolderLink()
        
        // Then
        #expect(root == expectedRoot)
    }
}
