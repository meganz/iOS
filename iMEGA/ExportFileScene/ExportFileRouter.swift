import Foundation
import UIKit

final class ExportFileRouter: ExportFileViewRouting {
    private weak var presenter: UIViewController?
    private let sender: Any?
    
    init(presenter: UIViewController, sender: Any?) {
        self.presenter = presenter
        self.sender = sender
    }
    
    //MARK: - Dispatch actions without viewcontroller -
    func export(node: NodeEntity) {
        viewModel().dispatch(.exportFileFromNode(node))
    }
    
    func export(nodes: [NodeEntity]) {
        viewModel().dispatch(.exportFilesFromNodes(nodes))
    }
    
    func export(messages: [MEGAChatMessage]) {
        viewModel().dispatch(.exportFilesFromMessages(messages))
    }
    
    func exportMessage(node: MEGANode) {
        viewModel().dispatch(.exportFileFromMessageNode(node))
    }
    
    //MARK: - Private -
    private func viewModel() -> ExportFileViewModel {
        ExportFileViewModel(router: self, exportFileUseCase: ExportFileUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk()), offlineFilesRepository: OfflineFilesRepository(store: MEGAStore.shareInstance()), fileSystemRepository: FileSystemRepository.default, exportChatMessagesRepository: ExportChatMessagesRepository.default, importNodeRepository: ImportNodeRepository.default))
    }
    
    //MARK: - ExportFileViewRouting -
    func exportedFiles(urls: [URL]) {
        let activityViewController = UIActivityViewController.init(activityItems: urls, applicationActivities: nil)
        
        if let viewSender = sender as? UIView {
            activityViewController.popoverPresentationController?.sourceView = viewSender
        } else if let buttonSender = sender as? UIBarButtonItem {
            activityViewController.popoverPresentationController?.barButtonItem = buttonSender
        }
        
        UIApplication.mnz_presentingViewController().present(activityViewController, animated: true, completion: nil)
    }
    
    func showProgressView() {
        guard let presenter = presenter else {
            return
        }

        TransfersWidgetViewController.sharedTransfer().showProgress(view: presenter.view, bottomAnchor: -100)
        TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
    }
    
    func hideProgressView() {
        TransfersWidgetViewController.sharedTransfer().progressView?.hideWidget()
        TransfersWidgetViewController.sharedTransfer().resetToMainTabBar()
    }
}
