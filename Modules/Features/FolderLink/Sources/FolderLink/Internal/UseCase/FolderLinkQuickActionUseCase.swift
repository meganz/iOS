import MEGADomain

protocol FolderLinkQuickActionUseCaseProtocol: Sendable {
    func quickActions(for nodeHandle: HandleEntity) -> [FolderLinkQuickAction]
}

struct FolderLinkQuickActionUseCase: FolderLinkQuickActionUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func quickActions(for nodeHandle: HandleEntity) -> [FolderLinkQuickAction] {
        guard let node = folderLinkRepository.node(for: nodeHandle), node.isNodeKeyDecrypted else { return [] }
        return [
            .importToCloudDrive,
            .downloadToOffline,
            .shareLink,
            .sendToChat
        ]
    }
    
}
