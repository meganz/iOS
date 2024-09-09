import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation

protocol TransferWidgetRouting: Routing {
    func prepareTransfersWidget()
}

@MainActor
final class CancellableTransferViewModel: ViewModelType, Sendable {
    typealias routingProtocols = CancellableTransferRouting & TransferWidgetRouting

    private let uploadFileUseCase: any UploadFileUseCaseProtocol
    private let downloadNodeUseCase: any DownloadNodeUseCaseProtocol
    private let mediaUseCase: any MediaUseCaseProtocol
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol

    private let transfers: [CancellableTransfer]
    private let fileTransfers: [CancellableTransfer]
    private let folderTransfers: [CancellableTransfer]
    private let transferType: CancellableTransferType
    
    private var transfersCancelled: Bool = false
    private var processingComplete: Bool = false
    private var isAlertBlocked: Bool = false

    private var transferErrors = [TransferErrorEntity]()
    
    private var alertSubscription: AnyCancellable?
    
    private var alertPresented = false

    // MARK: - Private properties
    private let router: any routingProtocols
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some routingProtocols,
         uploadFileUseCase: any UploadFileUseCaseProtocol,
         downloadNodeUseCase: any DownloadNodeUseCaseProtocol,
         mediaUseCase: any MediaUseCaseProtocol,
         analyticsEventUseCase: any AnalyticsEventUseCaseProtocol,
         transfers: [CancellableTransfer],
         transferType: CancellableTransferType) {
        self.router = router
        self.uploadFileUseCase = uploadFileUseCase
        self.downloadNodeUseCase = downloadNodeUseCase
        self.mediaUseCase = mediaUseCase
        self.analyticsEventUseCase = analyticsEventUseCase
        self.transfers = transfers
        self.fileTransfers = transfers.filter { $0.isFile }
        self.folderTransfers = transfers.filter { !$0.isFile }
        self.transferType = transferType
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: CancellableTransferViewAction) {
        switch action {
        case .onViewReady:
            router.prepareTransfersWidget()
            switch transferType {
            case .upload:
                if fileTransfers.isNotEmpty {
                    startFileUploads()
                } else {
                    startFolderUploads()
                }
            case .download:
                sendDownloadAnalyticsStats()
                if fileTransfers.isNotEmpty {
                    startFileDownloads()
                } else {
                    startFolderDownloads()
                }
            case .downloadChat:
                sendDownloadAnalyticsStats()
                Task(priority: .userInitiated) {
                    await startChatFileDownloads()
                }
            case .downloadFileLink:
                startFileLinkDownload()
            }
            showAlertViewIfNeeded()
        case .didTapCancelButton:
            if processingComplete {
                return
            }
            transfersCancelled = true
            if transferType == .upload {
                uploadFileUseCase.cancelUploadTransfers()
            } else {
                downloadNodeUseCase.cancelDownloadTransfers()
            }
            invokeCommand?(.cancelling)
        }
    }
    
    // MARK: - Private
    private func showAlertViewIfNeeded() {
        alertSubscription = Just(Void.self)
            .delay(for: .seconds(0.8), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.transfersCancelled, !self.processingComplete else {
                    self.alertSubscription?.cancel()
                    return
                }
                self.router.showTransfersAlert()
                self.alertPresented = true
                self.blockAlertView()
            }
    }
    
    private func blockAlertView() {
        isAlertBlocked = true
        alertSubscription = Just(Void.self)
            .delay(for: .seconds(1.2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.isAlertBlocked = false
                if (self.fileTransfersStarted() && self.folderTransfers.isEmpty || self.folderTransfersStartedTransferring()) && !self.transfersCancelled {
                    self.manageTransfersCompletion()
                }
            }
    }
    
    private func fileTransfersStarted() -> Bool {
        fileTransfers.filter({ $0.state != .none }).count == fileTransfers.count
    }
    
    private func folderTransfersStartedTransferring() -> Bool {
        folderTransfers.filter({ $0.state == .failed || $0.stage == .transferringFiles || $0.state == .complete }).count == folderTransfers.count
    }
    
    private func continueFolderTransfersIfNeeded() {
        guard fileTransfersStarted() else {
            return
        }
        
        if folderTransfers.isEmpty {
            manageTransfersCompletion()
        } else {
            switch transferType {
            case .download:
                startFolderDownloads()
            case .upload:
                startFolderUploads()
            default:
                break
            }
        }
    }
    
    private func checkIfAllTransfersStartedTransferring() {
        guard folderTransfersStartedTransferring() else {
            return
        }
        manageTransfersCompletion()
    }
    
    private func manageTransfersCompletion() {
        if processingComplete || isAlertBlocked {
            return
        }
        processingComplete = true
        alertSubscription?.cancel()
        alertSubscription = nil
        
        if transfersCancelled {
            router.transferCancelled(with: Strings.Localizable.transferCancelled, dismiss: alertPresented)
        } else if transferErrors.isEmpty {
            switch transferType {
            case .download, .downloadChat, .downloadFileLink:
                router.transferSuccess(with: Strings.Localizable.downloadStarted, dismiss: alertPresented)
            case .upload:
                router.transferSuccess(with: Strings.Localizable.uploadStartedMessage, dismiss: alertPresented)
            }
        } else if transferErrors.count < transfers.count {
            router.transferCompletedWithError(error: Strings.Localizable.somethingWentWrong, dismiss: alertPresented)
        } else {
            router.transferFailed(error: String(format: "%@ %@", Strings.Localizable.transferFailed, Strings.Localizable.somethingWentWrong), dismiss: alertPresented)
        }
    }
    
    // MARK: - Upload
    private func startFileUploads() {
        fileTransfers.forEach { transferViewEntity in
            guard let uploadLocalURL = transferViewEntity.localFileURL else {
                return
            }
            uploadFileUseCase.uploadFile(uploadLocalURL,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: transferViewEntity.name,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: true,
                                         startFirst: transferViewEntity.priority
            ) { transferEntity in
                transferViewEntity.setState(transferEntity.state)
                self.continueFolderTransfersIfNeeded()
            } update: { _ in } completion: { [weak self]  result in
                switch result {
                case .success:
                    transferViewEntity.setState(.complete)
                case .failure(let error):
                    transferViewEntity.setState(.failed)
                    self?.transferErrors.append(error)
                }
                self?.continueFolderTransfersIfNeeded()
            }
        }
    }
    
    private func startFolderUploads() {
        folderTransfers.forEach { transferViewEntity in
            guard let uploadLocalURL = transferViewEntity.localFileURL else {
                return
            }
            uploadFileUseCase.uploadFile(uploadLocalURL,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: nil,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: true,
                                         startFirst: transferViewEntity.priority,
                                         start: nil) { transferEntity in
                transferViewEntity.setStage(transferEntity.stage)
                transferViewEntity.setState(transferEntity.state)
                switch transferEntity.stage {
                case .transferringFiles:
                    self.checkIfAllTransfersStartedTransferring()
                default:
                    break
                }
            } completion: { [weak self]  result in
                switch result {
                case .success:
                    transferViewEntity.setState(.complete)
                case .failure(let error):
                    transferViewEntity.setState(.failed)
                    self?.transferErrors.append(error)
                    self?.checkIfAllTransfersStartedTransferring()
                }
            }
        }
    }
    
    private func downloadChatFile(transferViewEntity: CancellableTransfer) async {
        do {
            for try await status in try await downloadNodeUseCase.downloadChatFileToOffline(
                forNodeHandle: transferViewEntity.handle,
                messageId: transferViewEntity.messageId,
                chatId: transferViewEntity.chatId,
                filename: transferViewEntity.name,
                appdata: transferViewEntity.appData,
                startFirst: transferViewEntity.priority
            ) {
                switch status {
                case .start(let transferEntity):
                    transferViewEntity.setState(transferEntity.state)
                    continueFolderTransfersIfNeeded()
                case .update:
                    continue
                case .folderUpdate:
                    continue
                case .finish(let transferEntity):
                    transferViewEntity.setState(transferEntity.state)
                }
            }
        } catch let error as TransferErrorEntity {
            if error != .alreadyDownloaded && error != .copiedFromTempFolder {
                transferErrors.append(error)
            }
            continueFolderTransfersIfNeeded()
        } catch {
            MEGALogError("Download chat file failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Downloads
    private func startChatFileDownloads() async {
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTasksUnlessCancelled(for: fileTransfers, priority: .background) { transferViewEntity in
                await self.downloadChatFile(transferViewEntity: transferViewEntity)
            }
        }
    }

    private func startFileDownloads() {
        fileTransfers.forEach { transferViewEntity in
            downloadNodeUseCase.downloadFileToOffline(forNodeHandle: transferViewEntity.handle,
                                                      filename: transferViewEntity.name,
                                                      appdata: transferViewEntity.appData,
                                                      startFirst: transferViewEntity.priority) { transferEntity in
                transferViewEntity.setState(transferEntity.state)
                self.continueFolderTransfersIfNeeded()
            } update: { _ in } completion: { [weak self] result in
                switch result {
                case .success(let transferEntity):
                    transferViewEntity.setState(transferEntity.state)
                case .failure(let error):
                    transferViewEntity.setState(.failed)
                    if error != .alreadyDownloaded && error != .copiedFromTempFolder {
                        self?.transferErrors.append(error)
                    }
                    self?.continueFolderTransfersIfNeeded()
                }
            } folderUpdate: { _ in }
        }
    }
    
    private func startFileLinkDownload() {
        guard let transferViewEntity = fileTransfers[safe: 0], let linkUrl = transferViewEntity.fileLinkURL else {
            return
        }
        let fileLink = FileLinkEntity(linkURL: linkUrl)

        downloadNodeUseCase.downloadFileLinkToOffline(fileLink,
                                                      filename: transferViewEntity.name,
                                                      metaData: nil,
                                                      startFirst: transferViewEntity.priority) { transferEntity in
            transferViewEntity.setState(transferEntity.state)
            self.manageTransfersCompletion()
        } update: { _ in } completion: { [weak self] result in
            switch result {
            case .success(let transferEntity):
                transferViewEntity.setState(transferEntity.state)
            case .failure(let error):
                transferViewEntity.setState(.failed)
                if error != .alreadyDownloaded && error != .copiedFromTempFolder {
                    self?.transferErrors.append(error)
                }
                self?.manageTransfersCompletion()
            }
        }
    }
    
    private func startFolderDownloads() {
        folderTransfers.forEach { transferViewEntity in
            downloadNodeUseCase.downloadFileToOffline(forNodeHandle: transferViewEntity.handle,
                                                      filename: transferViewEntity.name,
                                                      appdata: transferViewEntity.appData,
                                                      startFirst: transferViewEntity.priority,
                                                      start: nil) { transferEntity in
                switch transferEntity.stage {
                case .transferringFiles:
                    transferViewEntity.setStage(transferEntity.stage)
                    transferViewEntity.setState(transferEntity.state)
                    self.checkIfAllTransfersStartedTransferring()
                default:
                    break
                }
            } completion: { [weak self] result in
                switch result {
                case .success(let transferEntity):
                    transferViewEntity.setState(transferEntity.state)
                case .failure(let error):
                    transferViewEntity.setState(.failed)
                    if error != .alreadyDownloaded && error != .copiedFromTempFolder {
                        self?.transferErrors.append(error)
                    }
                }
                self?.checkIfAllTransfersStartedTransferring()
            } folderUpdate: { [weak self] folderUpdate in
                guard let self else { return }
                switch folderUpdate.stage {
                case .scan:
                    self.invokeCommand?(.scanning(name: folderUpdate.transfer.fileName ?? "", folders: folderUpdate.folderCount, files: folderUpdate.fileCount))
                case .createTree:
                    self.invokeCommand?(.creatingFolders(createdFolders: folderUpdate.createdFolderCount, totalFolders: folderUpdate.folderCount))
                case .transferringFiles:
                    self.checkIfAllTransfersStartedTransferring()
                default:
                    break
                }
            }
        }
    }
    
    private func sendDownloadAnalyticsStats() {
        let multimediaNodesCount = transfers.filter { mediaUseCase.isMultimedia($0.name ?? "") == true }.count
        
        if multimediaNodesCount == transfers.count {
            analyticsEventUseCase.sendAnalyticsEvent(.download(.makeAvailableOfflinePhotosVideos))
        } else if multimediaNodesCount == 0 {
            analyticsEventUseCase.sendAnalyticsEvent(.download(.makeAvailableOffline))
        } else {
            analyticsEventUseCase.sendAnalyticsEvent(.download(.makeAvailableOfflinePhotosVideos))
            analyticsEventUseCase.sendAnalyticsEvent(.download(.makeAvailableOffline))
        }
    }
}
