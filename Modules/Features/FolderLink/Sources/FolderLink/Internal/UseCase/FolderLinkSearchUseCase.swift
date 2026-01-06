import MEGADomain

package protocol FolderLinkSearchUseCaseProtocol: Sendable {
    func rootFolderLink() -> HandleEntity
}

package struct FolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func rootFolderLink() -> HandleEntity {
        folderLinkRepository.getRootNode()
    }
}
