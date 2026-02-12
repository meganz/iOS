import FolderLink
import MEGADomain

final class MockFolderLinkTitleUseCase: FolderLinkTitleUseCaseProtocol, @unchecked Sendable {
    let titleType: FolderLinkTitleType
    private(set) var calledArguments: [(HandleEntity, Any)] = []
    
    init(titleType: FolderLinkTitleType = .generic) {
        self.titleType = titleType
    }
    
    func title<C>(for nodeHandle: HandleEntity, editingState: FolderLinkEditingState<C>) -> FolderLinkTitleType  {
        calledArguments.append((nodeHandle, editingState))
        return titleType
    }
}
