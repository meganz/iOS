import FolderLink
import MEGADomain
import Testing

struct FolderLinkBottomBarUseCaseTests {
    struct ShouldIncludeSaveToPhotosActionTests {
        @Suite("When editing is inactive")
        struct WhenEditingStateIsInactive {
            @Test("Returns true when has no children")
            func returnsFalseWhenFolderHasNoChildren() {
                // Given
                let folderHandle: HandleEntity = 100
                let repo = MockFolderLinkRepository(childrenByHandle: [folderHandle: []])
                let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
                
                // When
                let include = sut.shouldIncludeSaveToPhotosAction(
                    handle: folderHandle,
                    editingState: .inactive
                )
                
                // Then
                #expect(include == false)
            }
            
            @Test("Returns true when all children are media")
            func returnsTrueWhenAllChildrenAreMedia() {
                // Given
                let folderHandle: HandleEntity = 200
                let image = NodeEntity(handle: 201, mediaType: .image)
                let video = NodeEntity(handle: 202, mediaType: .video)
                let repo = MockFolderLinkRepository(childrenByHandle: [folderHandle: [image, video]])
                let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
                
                // When
                let include = sut.shouldIncludeSaveToPhotosAction(
                    handle: folderHandle,
                    editingState: .inactive
                )
                
                // Then
                #expect(include == true)
            }
            
            @Test("Returns false when any child is not media")
            func returnsFalseWhenAnyChildIsNotMediaAndEditingStateIsInactive() {
                // Given
                let folderHandle: HandleEntity = 300
                let media = NodeEntity(handle: 301, mediaType: .image)
                let nonMedia = NodeEntity(handle: 302, mediaType: nil)
                let repo = MockFolderLinkRepository(childrenByHandle: [folderHandle: [media, nonMedia]])
                let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
                
                // When
                let include = sut.shouldIncludeSaveToPhotosAction(
                    handle: folderHandle,
                    editingState: .inactive
                )
                
                // Then
                #expect(include == false)
            }
        }
        
        @Suite("When editing is active")
        struct WhenEditingStateIsActive {
            @Test("Returns true when all selected nodes are media")
            func returnsTrueWhenAllSelectedNodesAreMedia() {
                // Given
                let handles: Set<HandleEntity> = [400, 401]
                let node400 = NodeEntity(handle: 400, mediaType: .image)
                let node401 = NodeEntity(handle: 401, mediaType: .video)
                let repo = MockFolderLinkRepository(nodesByHandle: [400: node400, 401: node401])
                let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
                
                // When
                let include = sut.shouldIncludeSaveToPhotosAction(
                    handle: 999,
                    editingState: .active(handles)
                )
                
                // Then
                #expect(include == true)
            }
            
            @Test("Returns false when any selected node is not media")
            func returnsFalseWhenAnySelectedNodeIsNotMedia() {
                // Given
                let handles: Set<HandleEntity> = [500, 501]
                let media = NodeEntity(handle: 500, mediaType: .image)
                let nonMedia = NodeEntity(handle: 501, mediaType: nil)
                let repo = MockFolderLinkRepository(nodesByHandle: [500: media, 501: nonMedia])
                let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
                
                // When
                let include = sut.shouldIncludeSaveToPhotosAction(
                    handle: 0,
                    editingState: .active(handles)
                )
                
                // Then
                #expect(include == false)
            }
            
            @Test("Returns false when active selection resolves to no nodes")
            func returnsFalseWhenActiveSelectionResolvesToNoNodesAndEditingStateIsActive() {
                // Given
                let handles: Set<HandleEntity> = [600, 601]
                let repo = MockFolderLinkRepository(nodesByHandle: [:])
                let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
                
                // When
                let include = sut.shouldIncludeSaveToPhotosAction(
                    handle: 0,
                    editingState: .active(handles)
                )
                
                // Then
                #expect(include == false)
            }
        }
    }
    
    struct ShouldDisableBottomBarTests {
        @Test("Returns true when node is missing")
        func returnsTrueWhenNodeIsMissing() {
            // Given
            let handle: HandleEntity = 700
            let repo = MockFolderLinkRepository(nodesByHandle: [:])
            let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
            
            // When
            let disabled = sut.shouldDisableBottomBar(
                handle: handle,
                editingState: FolderLinkEditingState<Set<HandleEntity>>.inactive
            )
            
            // Then
            #expect(disabled == true)
        }
        
        @Test("Returns true when node key is not decrypted")
        func returnsTrueWhenNodeKeyIsNotDecrypted() {
            // Given
            let handle: HandleEntity = 800
            let node = NodeEntity(handle: handle, isNodeKeyDecrypted: false)
            let repo = MockFolderLinkRepository(nodesByHandle: [handle: node])
            let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
            
            // When
            let disabled = sut.shouldDisableBottomBar(
                handle: handle,
                editingState: FolderLinkEditingState<Set<HandleEntity>>.inactive
            )
            
            // Then
            #expect(disabled == true)
        }
        
        @Test("Returns false when node is decrypted and editing state is inactive")
        func returnsFalseWhenNodeIsDecryptedAndEditingStateIsInactive() {
            // Given
            let handle: HandleEntity = 900
            let node = NodeEntity(handle: handle, isNodeKeyDecrypted: true)
            let repo = MockFolderLinkRepository(nodesByHandle: [handle: node])
            let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
            
            // When
            let disabled = sut.shouldDisableBottomBar(
                handle: handle,
                editingState: FolderLinkEditingState<Set<HandleEntity>>.inactive
            )
            
            // Then
            #expect(disabled == false)
        }
        
        @Test("Returns true when selection is empty")
        func returnsTrueWhenSelectionIsEmpty() {
            // Given
            let handle: HandleEntity = 1000
            let node = NodeEntity(handle: handle, isNodeKeyDecrypted: true)
            let repo = MockFolderLinkRepository(nodesByHandle: [handle: node])
            let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
            
            // When
            let disabled = sut.shouldDisableBottomBar(
                handle: handle,
                editingState: FolderLinkEditingState<Set<HandleEntity>>.active([])
            )
            
            // Then
            #expect(disabled == true)
        }
        
        @Test("Returns false when selection is not empty")
        func returnsFalseWhenSelectionIsNotEmptyAndEditingStateIsActive() {
            // Given
            let handle: HandleEntity = 1100
            let node = NodeEntity(handle: handle, isNodeKeyDecrypted: true)
            let repo = MockFolderLinkRepository(nodesByHandle: [handle: node])
            let sut = FolderLinkBottomBarUseCase(folderLinkRepository: repo)
            
            // When
            let disabled = sut.shouldDisableBottomBar(
                handle: handle,
                editingState: FolderLinkEditingState<Set<HandleEntity>>.active([1])
            )
            
            // Then
            #expect(disabled == false)
        }
    }
}
