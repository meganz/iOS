import MEGADomain

protocol FolderLinkQuickActionUseCaseProtocol: Sendable {
    func shouldEnableQuickActions(for nodeHandle: HandleEntity) -> Bool
}

package struct FolderLinkQuickActionUseCase: FolderLinkQuickActionUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func shouldEnableQuickActions(for nodeHandle: HandleEntity) -> Bool {
        guard let node = folderLinkRepository.node(for: nodeHandle) else { return false }
        return node.isNodeKeyDecrypted
    }
}
