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
                _ = try await shareUseCase?.createShareKeys(forNodes: nodes.toNodeEntities())
                router.showShareFoldersContactView(withNodes: nodes)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
}
