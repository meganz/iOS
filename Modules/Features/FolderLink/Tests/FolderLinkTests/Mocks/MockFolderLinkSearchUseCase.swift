import FolderLink
import MEGADomain

final class MockFolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let root: HandleEntity
    
    init(root: HandleEntity = .invalid) {
        self.root = root
    }
    
    func rootFolderLink() -> HandleEntity { root }
}
