import FolderLink
import MEGADomain

final class MockFolderLinkBottomBarUseCase: FolderLinkBottomBarUseCaseProtocol, @unchecked Sendable {
    let saveToPhotoActionIncluded: Bool
    let bottomBarDisabled: Bool
    private(set) var shouldDisableBottomBarCalledArguments: [(HandleEntity, Any)] = []
    
    init(saveToPhotoActionIncluded: Bool = false, bottomBarDisabled: Bool = false) {
        self.saveToPhotoActionIncluded = saveToPhotoActionIncluded
        self.bottomBarDisabled = bottomBarDisabled
    }
    
    func shouldIncludeSaveToPhotosAction(handle: HandleEntity, editingState: FolderLinkEditingState<Set<HandleEntity>>) -> Bool {
        saveToPhotoActionIncluded
    }
    
    func shouldDisableBottomBar<C>(handle: HandleEntity, editingState: FolderLinkEditingState<C>) -> Bool {
        shouldDisableBottomBarCalledArguments.append((handle, editingState))
        return bottomBarDisabled
    }
}

