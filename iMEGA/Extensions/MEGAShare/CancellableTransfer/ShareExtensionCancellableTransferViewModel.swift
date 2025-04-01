import MEGAAppPresentation
import MEGADomain
import MEGAL10n

final class ShareExtensionCancellableTransferViewModel: ViewModelType {
    
    private let uploadFileUseCase: any UploadFileUseCaseProtocol
    
    private let transfers: [CancellableTransfer]
    private let fileTransfers: [CancellableTransfer]
    private let folderTransfers: [CancellableTransfer]
    
    private var transfersCancelled: Bool = false
    private var processingComplete: Bool = false

    private var transferErrors = [TransferErrorEntity]()
    
    private var alertPresented = false
    
    // MARK: - Private properties
    private let router: any CancellableTransferRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: some CancellableTransferRouting,
         uploadFileUseCase: any UploadFileUseCaseProtocol,
         transfers: [CancellableTransfer]) {
        self.router = router
        self.uploadFileUseCase = uploadFileUseCase
        self.transfers = transfers
        self.fileTransfers = transfers.filter { $0.isFile }
        self.folderTransfers = transfers.filter { !$0.isFile }
    }
    
    func dispatch(_ action: CancellableTransferViewAction) {
        switch action {
        case .onViewReady:
            invokeCommand?(.transferring)
            router.showTransfersAlert()
            if fileTransfers.isNotEmpty {
                startShareExtensionFileUploads()
            } else {
                startShareExtensionFolderUploads()
            }
            self.alertPresented = true
        case .didTapCancelButton:
            if processingComplete {
                return
            }
            transfersCancelled = true
            uploadFileUseCase.cancelUploadTransfers()
        }
    }
    
    // MARK: - Private
    private func fileTransfersFinished() -> Bool {
        fileTransfers.filter({ $0.state == .complete || $0.state == .failed }).count == fileTransfers.count
    }
    
    private func folderTransfersFinished() -> Bool {
        folderTransfers.filter({ $0.state == .complete || $0.state == .failed }).count == folderTransfers.count
    }
    
    private func checkIfAllTransfersComplete() {
        guard folderTransfersFinished(), !transfersCancelled else {
            return
        }
        manageTransfersCompletion()
    }
    
    private func continueFolderTransfersIfNeeded() {
        guard !transfersCancelled else {
            return
        }
        
        if fileTransfersFinished() {
            if folderTransfers.isEmpty {
                manageTransfersCompletion()
            } else {
                startShareExtensionFolderUploads()
            }
        }
    }
    
    private func manageTransfersCompletion() {
        processingComplete = true
        if transferErrors.isEmpty {
            router.transferSuccess(with: successShareMessage, dismiss: alertPresented)
        } else if transferErrors.count < transfers.count {
            router.transferCompletedWithError(error: Strings.Localizable.somethingWentWrong, dismiss: alertPresented)
        } else {
            router.transferFailed(error: String(format: "%@ %@", Strings.Localizable.transferFailed, Strings.Localizable.somethingWentWrong), dismiss: alertPresented)
        }
    }
    
    private var successShareMessage: String {
        guard let firstShare = transfers.first,
              let parentNode = uploadFileUseCase.nodeForHandle(firstShare.parentHandle) else { return "" }
        
        let transferCount = transfers.count
        let destinationFolderName = parentNode.name
        var successMessage = ""
        
        if parentNode.nodeType == .root {
            successMessage = Strings.Localizable.Share.Message.uploadedToCloudDrive(transferCount)
        } else {
            successMessage = Strings.Localizable.Share.Message.uploadedToDestinationFolder(transferCount)
                .replacingOccurrences(of: "[B]", with: destinationFolderName)
        }

        if transferCount == 1 {
            let shareName = firstShare.name ?? firstShare.localFileURL?.lastPathComponent ?? ""
            successMessage = successMessage.replacingOccurrences(of: "[A]", with: shareName)
        }
        return successMessage
    }
    
    // MARK: - Share extension upload
    private func startShareExtensionFileUploads() {
        fileTransfers.forEach { transferViewEntity in
            guard let uploadLocalURL = transferViewEntity.localFileURL else {
                return
            }
            uploadFileUseCase.uploadFile(uploadLocalURL,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: transferViewEntity.name,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: false,
                                         startFirst: transferViewEntity.priority) { transferEntity in
                transferViewEntity.setState(transferEntity.state)
            } update: { _ in } completion: { [weak self] result in
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
    
    private func startShareExtensionFolderUploads() {
        folderTransfers.forEach { transferViewEntity in
            guard let uploadLocalURL = transferViewEntity.localFileURL else {
                return
            }
            uploadFileUseCase.uploadFile(uploadLocalURL,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: nil,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: false,
                                         startFirst: transferViewEntity.priority,
                                         start: nil) { transferEntity in
                transferViewEntity.setStage(transferEntity.stage)
            } completion: { [weak self] result in
                switch result {
                case .success:
                    transferViewEntity.setState(.complete)
                case .failure(let error):
                    transferViewEntity.setState(.failed)
                    self?.transferErrors.append(error)
                }
                self?.checkIfAllTransfersComplete()
            }
        }
    }
}
