import Foundation
import MEGAAppSDKRepo
import MEGADomain

extension FolderLinkViewController {
    
    @objc func makeFolderLinkViewModel() -> FolderLinkViewModel {
        let viewModel = FolderLinkViewModel(
            folderLinkUseCase: FolderLinkUseCase(transferRepository: TransferRepository.newRepo)
        )
        viewModel.onNodeDownloadTransferFinish = { [weak self] handleEntity in
            guard let node = self?.isFromFolderLink(nodeHandle: handleEntity) else { return }
            self?.didDownloadTransferFinish(node)
        }
        return viewModel
    }
    
    private func isFromFolderLink(nodeHandle: HandleEntity) -> MEGANode? {
        return nodesArray.first(where: { $0.handle == nodeHandle })
    }
}

extension FolderLinkViewController {
    @objc func download(_ nodes: [MEGANode]) {
        DownloadLinkRouter(nodes: nodes.toNodeEntities(), isFolderLink: true, presenter: self).start()
    }
}
