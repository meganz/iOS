enum TextEditorViewAction: ActionType {
    case setUpView
    case saveText(_ content: String)
    case renameFile
    case renameFileTo(_ newInputName: String)
    case uploadFile
    case dismissTextEditorVC
    case editFile
    case showActions(sender: Any)
    case cancel
    case downloadFile
}

@objc enum TextEditorMode: Int, CaseIterable {
    case create
    case edit
    case view
    case load
}

protocol TextEditorViewRouting: Routing {
    func chooseParentNode(completion: @escaping (MEGAHandle) -> Void)
    func dismissTextEditorVC()
    func dismissBrowserVC()
    func showActions(sender button: Any, handle: MEGAHandle?)
    func showPreviewDocVC(fromFilePath path: String)
}

final class TextEditorViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(_ textEditorModel: TextEditorModel)
        case showDuplicateNameAlert(_ textEditorDuplicateNameAlertModel: TextEditorDuplicateNameAlertModel)
        case showRenameAlert(_ textEditorRenameAlertModel: TextEditorRenameAlertModel)
        case stopLoading
        case startLoading
        case editFile
        case updateProgressView(progress: Float)
        case showError(_ error: String)
    }
    
    var invokeCommand: ((Command) -> Void)?
    private var router: TextEditorViewRouting
    private var textFile: TextFile
    private var textEditorMode: TextEditorMode
    private var parentHandle: MEGAHandle?
    private var nodeHandle: MEGAHandle?
    private var uploadFileUseCase: UploadFileUseCaseProtocol
    private var downloadFileUseCase: DownloadFileUseCaseProtocol
    
    init(
        router: TextEditorViewRouting,
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        uploadFileUseCase: UploadFileUseCaseProtocol,
        downloadFileUseCase: DownloadFileUseCaseProtocol,
        parentHandle: MEGAHandle? = nil,
        nodeHandle: MEGAHandle? = nil
    ) {
        self.router = router
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.uploadFileUseCase = uploadFileUseCase
        self.downloadFileUseCase = downloadFileUseCase
        self.parentHandle = parentHandle
        self.nodeHandle = nodeHandle
    }
    
    func dispatch(_ action: TextEditorViewAction) {
        switch action {
        case .setUpView:
            invokeCommand?(.configView(makeTextEditorModel()))
        case .saveText(let content):
            saveText(content)
        case .renameFile:
            invokeCommand?(.showRenameAlert(makeTextEditorRenameAlertModel()))
        case .renameFileTo(let newInputName):
            renameFileTo(newInputName)
        case .uploadFile:
            uploadFile()
        case .dismissTextEditorVC:
            router.dismissTextEditorVC()
        case .editFile:
            textEditorMode = .edit
        case .showActions(sender: let button):
            router.showActions(sender: button, handle: nodeHandle)
        case .cancel:
            cancel()
        case .downloadFile:
            downloadFile()
        }
    }
    
    //MARK: - Private functions
    
    private func makeTextEditorModel() -> TextEditorModel {
        switch textEditorMode {
        case .load,
             .view:
            return TextEditorModel(
                leftButtonTitle: TextEditorL10n.close,
                rightButtonTitle: nil,
                textFile: textFile,
                textEditorMode: textEditorMode
            )
        case .edit,
             .create:
            return TextEditorModel(
                 leftButtonTitle: TextEditorL10n.cancel,
                 rightButtonTitle: TextEditorL10n.save,
                 textFile: textFile,
                 textEditorMode: textEditorMode
             )
        }
    }
    
    private func saveText(_ content: String) {
        textFile.content = content
        if textEditorMode == .edit {
            invokeCommand?(.startLoading)
            uploadFile()
        } else if textEditorMode == .create {
            router.chooseParentNode { (parentHandle) in
                self.uploadTo(parentHandle)
            }
        }
    }
    
    private func makeTextEditorRenameAlertModel() -> TextEditorRenameAlertModel {
        TextEditorRenameAlertModel(
            alertTitle: TextEditorL10n.rename,
            alertMessage: TextEditorL10n.renameAlertMessage,
            cancelButtonTitle: TextEditorL10n.cancel,
            renameButtonTitle: TextEditorL10n.rename,
            textFileName: textFile.fileName
        )
    }
    
    private func renameFileTo(_ newInputName: String) {
        textFile.fileName = newInputName
        guard let parentHandle = parentHandle else { return }
        uploadTo(parentHandle)
    }
    
    private func uploadFile() {
        guard let parentHandle = parentHandle else { return }
        let fileName = textFile.fileName
        let content = textFile.content
        let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        do {
            try content.write(toFile: tempPath, atomically: true, encoding: .utf8)
            uploadFileUseCase.uploadFile(withLocalPath: tempPath, toParent: parentHandle) { (result) in
                if self.textEditorMode == .edit {
                    self.invokeCommand?(.stopLoading)
                }
                
                switch result {
                case .failure(_):
                    self.invokeCommand?(.showError(TextEditorL10n.transferError + " " + TextEditorL10n.upload))
                case .success(_):
                    if self.textEditorMode == .edit {
                        self.textEditorMode = .view
                        self.invokeCommand?(.configView(self.makeTextEditorModel()))
                    }
                }
            }
            if self.textEditorMode == .create {
                router.dismissTextEditorVC()
            }
        } catch {
            MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
        }
    }
    
    private func cancel() {
        if textEditorMode == .create {
            router.dismissTextEditorVC()
        } else if textEditorMode == .edit{
            textEditorMode = .view
            invokeCommand?(.configView(makeTextEditorModel()))
        }
    }
    
    private func downloadFile() {
        guard let nodeHandle = nodeHandle else { return }
        downloadFileUseCase.DownloadFile(nodeHandle: nodeHandle) { (transferEntity) in
            guard let transferredBytes = transferEntity.transferredBytes,
                  let totalBytes = transferEntity.totalBytes
            else { return }
            let percentage = transferredBytes / totalBytes
            self.invokeCommand?(.updateProgressView(progress: percentage))
        } completion: { (result) in
            switch result {
            case .failure(_):
                self.invokeCommand?(.showError(TextEditorL10n.transferError + " " + TextEditorL10n.download))
            case .success(let transferEntity):
                guard let path = transferEntity.path else { return }
                do {
                    self.textFile.content = try String(contentsOfFile: path)
                    self.textEditorMode = .view
                    self.invokeCommand?(.configView(self.makeTextEditorModel()))
                } catch {
                    self.router.dismissTextEditorVC()
                    self.router.showPreviewDocVC(fromFilePath: path)
                }
                self.nodeHandle = nodeHandle
            }
        }
    }
    
    private func uploadTo(_ parentHandle: MEGAHandle) {
        self.parentHandle = parentHandle
        let isFileNameDuplicated = uploadFileUseCase.hasExistFile(name: textFile.fileName, parentHandle: parentHandle)
        if isFileNameDuplicated {
            invokeCommand?(.showDuplicateNameAlert(
                TextEditorDuplicateNameAlertModel(
                    alertTitle: String(format: TextEditorL10n.duplicateNameAlertTitle, textFile.fileName),
                    alertMessage: TextEditorL10n.duplicateNameAlertMessage,
                    cancelButtonTitle: TextEditorL10n.cancel,
                    replaceButtonTitle: TextEditorL10n.replace,
                    renameButtonTitle: TextEditorL10n.rename)
            ))
        } else {
            uploadFile()
            router.dismissBrowserVC()
        }
    }
}
