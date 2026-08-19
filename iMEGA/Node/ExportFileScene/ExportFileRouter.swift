import ChatRepo
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo
import UIKit

@MainActor
protocol IncompleteDownloadAlertRouting {
    /// Tells the user that part of the selection never made it onto the device, and returns only once they
    /// have acknowledged it, so the caller can carry on with whatever did arrive.
    func warnDownloadIncomplete(downloadedCount: Int, failedCount: Int) async
}

@MainActor
final class ExportFileRouter: ExportFileViewRouting {
    private weak var presenter: UIViewController?
    private let sender: Any?
    private let popoverSourceRect: CGRect?
    private let isFolderLink: Bool
    private let incompleteDownloadAlertRouter: (any IncompleteDownloadAlertRouting)?

    init(
        presenter: UIViewController,
        sender: Any?,
        popoverSourceRect: CGRect? = nil,
        isFolderLink: Bool = false,
        incompleteDownloadAlertRouter: (any IncompleteDownloadAlertRouting)? = nil
    ) {
        self.presenter = presenter
        self.sender = sender
        self.popoverSourceRect = popoverSourceRect
        self.isFolderLink = isFolderLink
        self.incompleteDownloadAlertRouter = incompleteDownloadAlertRouter
    }
    
    // MARK: - Dispatch actions without viewcontroller -
    /// - Returns: The work the export runs on, so a caller that needs to know when it is over can await it.
    ///   Every caller that only fires and forgets can keep ignoring it.
    @discardableResult
    func export(node: NodeEntity) -> Task<Void, Never>? {
        dispatch(.exportFileFromNode(node))
    }

    @discardableResult
    func export(nodes: [NodeEntity]) -> Task<Void, Never>? {
        dispatch(.exportFilesFromNodes(nodes))
    }
    
    private func dispatch(_ action: ExportFileAction) -> Task<Void, Never>? {
        let viewModel = createViewModel()
        viewModel.dispatch(action)
        return viewModel.currentTask
    }

    func export(messages: [ChatMessageEntity], chatId: HandleEntity) {
        createViewModel().dispatch(.exportFilesFromMessages(messages, chatId))
    }
    
    func exportMessage(node: MEGANode, messageId: HandleEntity, chatId: HandleEntity) {
        createViewModel().dispatch(.exportFileFromMessageNode(node, messageId, chatId))
    }
    
    // MARK: - Private -
    private func createViewModel() -> ExportFileViewModel {
        let exportFileUC = ExportFileUseCase(
            // A folder link node lives in its own SDK instance, so the download that backs the export
            // has to be told where to look for it.
            downloadFileRepository: DownloadFileRepository(
                sdk: .sharedSdk,
                sharedFolderSdk: isFolderLink ? .sharedFolderLink : nil
            ),
            offlineFilesRepository: OfflineFilesRepository.newRepo,
            fileCacheRepository: FileCacheRepository.newRepo,
            thumbnailRepository: ThumbnailRepository.newRepo,
            fileSystemRepository: FileSystemRepository.sharedRepo,
            exportChatMessagesRepository: ExportChatMessagesRepository.newRepo,
            importNodeRepository: ImportNodeRepository.newRepo,
            megaHandleRepository: MEGAHandleRepository.newRepo,
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            offlineFileFetcherRepository: OfflineFileFetcherRepository.newRepo,
            userStoreRepository: UserStoreRepository.newRepo,
            handsOverIncompleteFolders: incompleteDownloadAlertRouter != nil
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
    }
    
    // MARK: - ExportFileViewRouting -
    func exportedFiles(urls: [URL]) {
        let activityViewController = UIActivityViewController.init(activityItems: urls, applicationActivities: nil)
        
        if let viewSender = sender as? UIView {
            activityViewController.popoverPresentationController?.sourceView = viewSender
            activityViewController.popoverPresentationController?.sourceRect = popoverSourceRect ?? viewSender.bounds
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

    func warnDownloadIncomplete(downloadedCount: Int, failedCount: Int) async {
        await incompleteDownloadAlertRouter?.warnDownloadIncomplete(
            downloadedCount: downloadedCount,
            failedCount: failedCount
        )
    }
}
