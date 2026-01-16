import MEGADomain

protocol FolderLinkTitleUseCaseProtocol: Sendable {
    func title(for nodeHandle: HandleEntity, editingState: FolderLinkEditingState) -> FolderLinkTitleType
}

struct FolderLinkTitleUseCase: FolderLinkTitleUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func title(for nodeHandle: HandleEntity, editingState: FolderLinkEditingState) -> FolderLinkTitleType {
        switch editingState {
        case let .active(nodeHandles):
            if nodeHandles.isEmpty {
                .askForSelecting
            } else {
                .selectedItems(nodeHandles.count)
            }
        case .inactive:
            if let node = folderLinkRepository.node(for: nodeHandle) {
                node.isNodeKeyDecrypted ? .folderNodeName(node.name) : .undecryptedFolder
            } else {
                .generic
            }
        }
    }
}
