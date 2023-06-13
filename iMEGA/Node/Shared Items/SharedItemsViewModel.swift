import MEGADomain
import MEGAData

@MainActor
@objc final class SharedItemsViewModel: NSObject {
    
    private let router = SharedItemsViewRouter()
    private let shareUseCase: any ShareUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol
    
    init(shareUseCase: any ShareUseCaseProtocol,
         mediaUseCase: any MediaUseCaseProtocol,
         saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol) {
        self.shareUseCase = shareUseCase
        self.mediaUseCase = mediaUseCase
        self.saveMediaToPhotosUseCase = saveMediaToPhotosUseCase
    }

    func openShareFolderDialog(forNodes nodes: [MEGANode]) {
        Task {
            do {
                _ = try await shareUseCase.createShareKeys(forNodes: nodes.toNodeEntities())
                router.showShareFoldersContactView(withNodes: nodes)
            } catch {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
        }
    }
    
    @objc func showPendingOutShareModal(for email: String) {
        router.showPendingOutShareModal(for: email)
    }
    
    @objc func areMediaNodes(_ nodes: [MEGANode]) -> Bool {
        guard nodes.isNotEmpty else { return false }
        return nodes.allSatisfy { mediaUseCase.isPlayableMediaFile($0.toNodeEntity()) }
    }
    
    @objc func saveNodesToPhotos(_ nodes: [MEGANode]) async {
        guard areMediaNodes(nodes) else { return }
        do {
            try await saveMediaToPhotosUseCase.saveToPhotos(nodes: nodes.toNodeEntities())
        } catch {
            if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                await SVProgressHUD.dismiss()
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: error.localizedDescription)
            }
        }
    }
}
