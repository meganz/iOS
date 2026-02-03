import MEGAAppSDKRepo
import MEGADomain
import Search

package protocol FolderLinkSearchUseCaseProtocol: Sendable {
    func rootFolderLink() -> HandleEntity
}

package struct FolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    private let filesSearchUseCase: any FilesSearchUseCaseProtocol
    
    package init(
        folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo,
        filesSearchUseCase: some FilesSearchUseCaseProtocol = FilesSearchUseCase(repo: FilesSearchRepository(sdk: .sharedFolderLinkSdk), nodeRepository: NodeRepository.newRepo)
    ) {
        self.folderLinkRepository = folderLinkRepository
        self.filesSearchUseCase = filesSearchUseCase
    }
    
    package func rootFolderLink() -> HandleEntity {
        folderLinkRepository.getRootNode()
    }
}
