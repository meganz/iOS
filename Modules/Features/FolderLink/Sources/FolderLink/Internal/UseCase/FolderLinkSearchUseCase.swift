import MEGADomain

package protocol FolderLinkSearchUseCaseProtocol: Sendable {
    func rootFolderLink() -> HandleEntity
    func children(of nodeHandle: HandleEntity, order: SortOrderEntity) async -> [NodeEntity]
}

package struct FolderLinkSearchUseCase: FolderLinkSearchUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func rootFolderLink() -> HandleEntity {
        folderLinkRepository.getRootNode()
    }
    
    package func children(of nodeHandle: HandleEntity, order: SortOrderEntity) async -> [NodeEntity] {
        await folderLinkRepository.children(of: nodeHandle, order: order)
    }
}
