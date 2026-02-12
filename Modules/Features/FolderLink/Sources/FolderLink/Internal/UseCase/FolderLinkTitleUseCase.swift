import MEGADomain

package protocol FolderLinkTitleUseCaseProtocol: Sendable {
    func title<C>(for nodeHandle: HandleEntity, editingState: FolderLinkEditingState<C>) -> FolderLinkTitleType
}

package struct FolderLinkTitleUseCase: FolderLinkTitleUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    package init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    package func title<C>(for nodeHandle: HandleEntity, editingState: FolderLinkEditingState<C>) -> FolderLinkTitleType {
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
