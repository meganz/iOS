import MEGADomain
import Search

package protocol FolderLinkSearchUseCaseProtocol: Sendable {
    func rootFolderLink() -> NodeEntity?
}

package struct FolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(
        folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo
    ) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func rootFolderLink() -> NodeEntity? {
        folderLinkRepository.node(for: folderLinkRepository.getRootNode())
    }
}
