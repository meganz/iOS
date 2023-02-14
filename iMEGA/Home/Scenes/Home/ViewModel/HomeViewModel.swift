import MEGADomain

@objc final class HomeViewModel: NSObject {
    private let shareUseCase: ShareUseCaseProtocol
    
    init(shareUseCase: ShareUseCaseProtocol) {
        self.shareUseCase = shareUseCase
    }
    
    @MainActor
    func openShareFolderDialog(forNode node: MEGANode, router: HomeRouter?) {
        Task {
            do {
                let _ = try await shareUseCase.createShareKey(forNode: node.toNodeEntity())
                router?.didTap(on: .shareFolder(node))
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
}
