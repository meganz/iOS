import FolderLink
import MEGADomain
import Testing

struct FolderLinkTitleUseCaseTests {
    @Suite("When editing is inactive")
    struct WhenEditingStateIsInactive {
        @Test("Returns generic type when node is missing")
        func returnsGenericTypeWhenNodeIsMisisng() {
            // Given
            let folderHandle: HandleEntity = 100
            let repo = MockFolderLinkRepository(nodesByHandle: [:])
            let sut = FolderLinkTitleUseCase(folderLinkRepository: repo)
            
            // When
            let titleType = sut.title(for: folderHandle, editingState: FolderLinkEditingState<Set<HandleEntity>>.inactive)
            
            // Then
            #expect(titleType == .generic)
        }
        
        @Test("Returns undecryptedFolder type node is not decrypted")
        func returnsUndecryptedFolderTypeWhenNodeIsNotDecrypted() {
            // Given
            let node = NodeEntity(handle: 100, isNodeKeyDecrypted: false)
            let repo = MockFolderLinkRepository(nodesByHandle: [100: node])
            let sut = FolderLinkTitleUseCase(folderLinkRepository: repo)
            
            // When
            let titleType = sut.title(for: node.handle, editingState: FolderLinkEditingState<Set<HandleEntity>>.inactive)
            
            // Then
            #expect(titleType == .undecryptedFolder)
        }
        
        @Test("Returns node name type node is decrypted")
        func returnsNodeNameTypeWhenNodeIsNotDecrypted() {
            // Given
            let nodeName = "node100"
            let node = NodeEntity(name: nodeName, handle: 100, isNodeKeyDecrypted: true)
            let repo = MockFolderLinkRepository(nodesByHandle: [100: node])
            let sut = FolderLinkTitleUseCase(folderLinkRepository: repo)
            
            // When
            let titleType = sut.title(for: node.handle, editingState: FolderLinkEditingState<Set<HandleEntity>>.inactive)
            
            // Then
            #expect(titleType == .folderNodeName(nodeName))
        }
    }
    
    @Suite("When editing is active")
    struct WhenEditingStateIsActive {
        @Test("Returns askForSelecting type when seleciton is empty")
        func returnsAskForSelectingTypeWhenSelectionIsEmpty() {
            // Given
            let repo = MockFolderLinkRepository()
            let sut = FolderLinkTitleUseCase(folderLinkRepository: repo)
            
            // When
            let titleType = sut.title(for: 100, editingState: FolderLinkEditingState<Set<HandleEntity>>.active([]))
            
            // Then
            #expect(titleType == .askForSelecting)
        }
        
        @Test("Returns selectedItems type when seleciton is not empty")
        func returnsSelectedItemsTypeWhenSelectionIsEmpty() {
            // Given
            let selection: Set<HandleEntity> = [100, 200]
            let repo = MockFolderLinkRepository()
            let sut = FolderLinkTitleUseCase(folderLinkRepository: repo)
            
            // When
            let titleType = sut.title(for: 0, editingState: FolderLinkEditingState<Set<HandleEntity>>.active(selection))
            
            // Then
            #expect(titleType == .selectedItems(selection.count))
        }
    }
}
