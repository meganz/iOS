import MEGADomain

@objc final class CloudDriveViewModel: NSObject {
    private let router = SharedItemsViewRouter()
    private let shareUseCase: ShareUseCaseProtocol?
    
    init(shareUseCase: ShareUseCaseProtocol) {
        self.shareUseCase = shareUseCase
    }
    
    func openShareFolderDialog(forNodes nodes: [MEGANode]) {
        Task { @MainActor [shareUseCase] in
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    nodes.forEach { node in
                        group.addTask {
                            let _ = try await shareUseCase?.createShareKey(forNode: node.toNodeEntity())
                        }
                    }
                    try await group.next()
                }
                router.showShareFoldersContactView(withNodes: nodes)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
}
