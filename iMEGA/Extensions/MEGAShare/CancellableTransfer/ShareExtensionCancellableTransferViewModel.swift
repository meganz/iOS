
final class ShareExtensionCancellableTransferViewModel: ViewModelType {
    
    private let uploadFileUseCase: UploadFileUseCaseProtocol
    
    private let transfers: [CancellableTransfer]
    private let fileTransfers: [CancellableTransfer]
    private let folderTransfers: [CancellableTransfer]
    
    private let cancelToken = MEGACancelToken()
    private var processingComplete: Bool = false

    private var transferErrors = [TransferErrorEntity]()
    
    // MARK: - Private properties
    private let router: CancellableTransferRouting
    // MARK: - Internel properties
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    init(router: CancellableTransferRouting,
         uploadFileUseCase: UploadFileUseCaseProtocol,
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
            if fileTransfers.isNotEmpty {
                startShareExtensionFileUploads()
            } else {
                startShareExtensionFolderUploads()
            }
        case .didTapCancelButton:
            if processingComplete {
                return
            }
            router.showConfirmCancel()
        case .didTapDismissConfirmCancel:
            router.dismissConfirmCancel()
        case .didTapProceedCancel:
            cancelToken.cancel()
            router.transferCancelled(with: Strings.Localizable.transferCancelled)
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
        guard folderTransfersFinished(), !cancelToken.isCancelled else {
            return
        }
        manageTransfersCompletion()
    }
    
    private func continueFolderTransfersIfNeeded() {
        guard !cancelToken.isCancelled else {
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
            router.transferSuccess(with: Strings.Localizable.sharedSuccessfully)
        } else if transferErrors.count < transfers.count {
            router.transferCompletedWithError(error: Strings.Localizable.somethingWentWrong)
        } else {
            router.transferFailed(error: String(format: "%@ %@", Strings.Localizable.transferFailed, Strings.Localizable.somethingWentWrong))
        }
    }
    
    //MARK: - Share extension upload
    private func startShareExtensionFileUploads() {
        fileTransfers.forEach { transferViewEntity in
            uploadFileUseCase.uploadFile(withLocalPath: transferViewEntity.path,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: transferViewEntity.name,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: false,
                                         startFirst: transferViewEntity.priority,
                                         cancelToken: cancelToken)
            { transferEntity in
                transferViewEntity.state = transferEntity.state
            } update: { _ in } completion: { [weak self] result in
                switch result {
                case .success:
                    transferViewEntity.state = .complete
                case .failure(let error):
                    transferViewEntity.state = .failed
                    self?.transferErrors.append(error)
                }
                self?.continueFolderTransfersIfNeeded()
            }
        }
    }
    
    private func startShareExtensionFolderUploads() {
        folderTransfers.forEach { transferViewEntity in
            uploadFileUseCase.uploadFile(withLocalPath: transferViewEntity.path,
                                         toParent: transferViewEntity.parentHandle,
                                         fileName: nil,
                                         appData: transferViewEntity.appData,
                                         isSourceTemporary: false,
                                         startFirst: transferViewEntity.priority,
                                         cancelToken: cancelToken,
                                         start: nil)
            { transferEntity in
                transferViewEntity.stage = transferEntity.stage
            } completion: { [weak self] result in
                switch result {
                case .success:
                    transferViewEntity.state = .complete
                case .failure(let error):
                    transferViewEntity.state = .failed
                    self?.transferErrors.append(error)
                }
                self?.checkIfAllTransfersComplete()
            }
        }
    }
    
}
