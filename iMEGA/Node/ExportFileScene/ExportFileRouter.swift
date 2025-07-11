import ChatRepo
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import UIKit

@MainActor
final class ExportFileRouter: ExportFileViewRouting {
    private weak var presenter: UIViewController?
    private let sender: Any?
    
    init(presenter: UIViewController, sender: Any?) {
        self.presenter = presenter
        self.sender = sender
    }
    
    // MARK: - Dispatch actions without viewcontroller -
    func export(node: NodeEntity) {
        viewModel.dispatch(.exportFileFromNode(node))
    }
    
    func export(nodes: [NodeEntity]) {
        viewModel.dispatch(.exportFilesFromNodes(nodes))
    }
    
    func export(messages: [ChatMessageEntity], chatId: HandleEntity) {
        viewModel.dispatch(.exportFilesFromMessages(messages, chatId))
    }
    
    func exportMessage(node: MEGANode, messageId: HandleEntity, chatId: HandleEntity) {
        viewModel.dispatch(.exportFileFromMessageNode(node, messageId, chatId))
    }
    
    // MARK: - Private -
    private lazy var viewModel: ExportFileViewModel = {
        let exportFileUC = ExportFileUseCase(
            downloadFileRepository: DownloadFileRepository.newRepo,
            offlineFilesRepository: OfflineFilesRepository.newRepo,
            fileCacheRepository: FileCacheRepository.newRepo,
            thumbnailRepository: ThumbnailRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo,
            exportChatMessagesRepository: ExportChatMessagesRepository.newRepo,
            importNodeRepository: ImportNodeRepository.newRepo,
            megaHandleRepository: MEGAHandleRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            offlineFileFetcherRepository: OfflineFileFetcherRepository.newRepo,
            userStoreRepository: UserStoreRepository.newRepo
        )
        
        let overDiskQuotaChecker = OverDiskQuotaChecker(
            accountStorageUseCase: AccountStorageUseCase(
                accountRepository: AccountRepository.newRepo,
                preferenceUseCase: PreferenceUseCase.default),
            appDelegateRouter: AppDelegateRouter())
        
        return ExportFileViewModel(
            router: self,
            analyticsEventUseCase: AnalyticsEventUseCase(repository: AnalyticsRepository.newRepo),
            exportFileUseCase: exportFileUC,
            overDiskQuotaChecker: overDiskQuotaChecker)
    }()
    
    // MARK: - ExportFileViewRouting -
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
        TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
        TransfersWidgetViewController.sharedTransfer().showProgress(view: presenter.view, bottomAnchor: -100)
        TransfersWidgetViewController.sharedTransfer().progressView?.showWidgetIfNeeded()
    }
    
    func hideProgressView() {
        TransfersWidgetViewController.sharedTransfer().progressView?.hideWidget(widgetFobidden: true)
        TransfersWidgetViewController.sharedTransfer().resetToKeyWindow()
    }
}
