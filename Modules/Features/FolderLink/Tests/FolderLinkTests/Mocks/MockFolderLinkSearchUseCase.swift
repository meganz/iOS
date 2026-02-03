import FolderLink
import MEGADomain
import Search

final class MockFolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let root: HandleEntity
    
    init(root: HandleEntity = .invalid) {
        self.root = root
    }
    
    func rootFolderLink() -> HandleEntity { root }
}
