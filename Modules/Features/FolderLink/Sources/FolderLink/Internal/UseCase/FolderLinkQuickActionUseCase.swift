import MEGADomain

protocol FolderLinkQuickActionUseCaseProtocol: Sendable {
    func shouldEnableQuickActions(for nodeHandle: HandleEntity) -> Bool
}

struct FolderLinkQuickActionUseCase: FolderLinkQuickActionUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func shouldEnableQuickActions(for nodeHandle: HandleEntity) -> Bool {
        guard let node = folderLinkRepository.node(for: nodeHandle) else { return false }
        return node.isNodeKeyDecrypted
    }
}
