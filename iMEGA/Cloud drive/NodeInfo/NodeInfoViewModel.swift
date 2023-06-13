import MEGADomain

@objc final class NodeInfoViewModel: NSObject {
    private let router = SharedItemsViewRouter()
    private let shareUseCase: (any ShareUseCaseProtocol)?
    
    var node: MEGANode
    var isNodeUndecryptedFolder: Bool
    
    init(withNode node: MEGANode,
         shareUseCase: (any ShareUseCaseProtocol)? = nil,
         isNodeUndecryptedFolder: Bool = false) {
        self.shareUseCase = shareUseCase
        self.node = node
        self.isNodeUndecryptedFolder = isNodeUndecryptedFolder
    }
    
    @MainActor
    func openSharedDialog() {
        guard node.isFolder() else {
            router.showShareFoldersContactView(withNodes: [node])
            return
        }
        
        Task {
            do {
                _ = try await shareUseCase?.createShareKeys(forNodes: [node.toNodeEntity()])
                router.showShareFoldersContactView(withNodes: [node])
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
}
