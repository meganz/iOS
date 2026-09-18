import FolderLink
import MEGADomain
import Search

final class MockFolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let root: NodeEntity?
    
    init(root: NodeEntity? = nil) {
        self.root = root
    }
    
    func rootFolderLink() -> NodeEntity? { root }
}
