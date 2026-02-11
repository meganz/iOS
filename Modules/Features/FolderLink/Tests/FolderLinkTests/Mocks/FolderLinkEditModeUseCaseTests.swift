import FolderLink
import MEGADomain
import Testing

@Suite("FolderLinkEditModeUseCase Tests")
struct FolderLinkEditModeUseCaseTests {
    
    @Test("Returns false when folder has no children")
    func returnsFalseWhenFolderHasNoChildren() {
        // Given
        let repo = MockFolderLinkRepository()
        let sut = FolderLinkEditModeUseCase(folderLinkRepository: repo)
        let folderHandle: HandleEntity = 100
        
        // When
        let canEnter = sut.canEnterEditModeWhenOpeningFolder(folderHandle)
        
        // Then
        #expect(canEnter == false)
    }
    
    @Test("Returns true when folder has at least one child")
    func returnsTrueWhenFolderHasChildren() {
        // Given
        let folderHandle: HandleEntity = 200
        let child = NodeEntity(handle: 201)
        let repo = MockFolderLinkRepository(childrenByHandle: [folderHandle: [child]])
        let sut = FolderLinkEditModeUseCase(folderLinkRepository: repo)
        
        // When
        let canEnter = sut.canEnterEditModeWhenOpeningFolder(folderHandle)
        
        // Then
        #expect(canEnter == true)
    }
    
    @Test("Returns false when children exist for a different handle")
    func returnsFalseWhenChildrenAreForDifferentHandle() {
        // Given
        let askedHandle: HandleEntity = 300
        let otherHandle: HandleEntity = 301
        let child = NodeEntity(handle: 302)
        let repo = MockFolderLinkRepository(childrenByHandle: [otherHandle: [child]])
        let sut = FolderLinkEditModeUseCase(folderLinkRepository: repo)
        
        // When
        let canEnter = sut.canEnterEditModeWhenOpeningFolder(askedHandle)
        
        // Then
        #expect(canEnter == false)
    }
}
