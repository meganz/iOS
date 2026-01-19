import MEGADomain

protocol FolderLinkBottomBarUseCaseProtocol: Sendable {
    func shouldIncludeSaveToPhotosAction(handle: HandleEntity, editingState: FolderLinkEditingState) -> Bool
    func shouldDisableBottomBar(handle: HandleEntity, editingState: FolderLinkEditingState) -> Bool
}

struct FolderLinkBottomBarUseCase: FolderLinkBottomBarUseCaseProtocol {
    private let folderLinkRepository: any FolderLinkRepositoryProtocol
    
    init(folderLinkRepository: some FolderLinkRepositoryProtocol = FolderLinkRepository.newRepo) {
        self.folderLinkRepository = folderLinkRepository
    }
    
    func shouldIncludeSaveToPhotosAction(handle: HandleEntity, editingState: FolderLinkEditingState) -> Bool {
        let nodes = switch editingState {
        case .inactive:
            folderLinkRepository.children(of: handle)
        case let .active(nodeHandles):
            nodeHandles.compactMap { folderLinkRepository.node(for: $0) }
        }
        
        return if nodes.isEmpty {
            false
        } else {
            nodes.allSatisfy { $0.mediaType != nil }
        }
    }
    
    func shouldDisableBottomBar(handle: HandleEntity, editingState: FolderLinkEditingState) -> Bool {
        guard let node = folderLinkRepository.node(for: handle), node.isNodeKeyDecrypted else { return true }
        return switch editingState {
        case .inactive:
            false
        case let .active(selectedNodes):
            selectedNodes.isEmpty
        }
    }
}
