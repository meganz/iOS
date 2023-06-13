import MEGADomain

@objc final class HomeViewModel: NSObject {
    private let shareUseCase: any ShareUseCaseProtocol
    
    init(shareUseCase: any ShareUseCaseProtocol) {
        self.shareUseCase = shareUseCase
    }
    
    @MainActor
    func openShareFolderDialog(forNode node: MEGANode, router: HomeRouter?) {
        Task {
            do {
                _ = try await shareUseCase.createShareKeys(forNodes: [node.toNodeEntity()])
                router?.didTap(on: .shareFolder(node))
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
}
