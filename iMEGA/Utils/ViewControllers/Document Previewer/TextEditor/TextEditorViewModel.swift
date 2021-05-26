enum TextEditorViewAction: ActionType {
    case setUpView
    case saveText(content: String)
    case renameFile
    case renameFileTo(newInputName: String)
    case uploadFile
    case dismissTextEditorVC
    case editFile
    case showActions(sender: Any)
    case cancelText(content: String)
    case cancel
    case downloadToOffline
    case importNode
    case share(sender: Any)
    case editAfterOpen
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
    func showActions(sender button: Any)
    func showPreviewDocVC(fromFilePath path: String)
    func importNode(nodeHandle: MEGAHandle?)
    func share(nodeHandle: MEGAHandle?, sender button: Any)
}

final class TextEditorViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(_ textEditorModel: TextEditorModel, shallUpdateContent: Bool)
        case setupNavbarItems(_ navbarItemsModel: TextEditorNavbarItemsModel)
        case setupLoadViews
        case showDuplicateNameAlert(_ textEditorDuplicateNameAlertModel: TextEditorDuplicateNameAlertModel)
        case showRenameAlert(_ textEditorRenameAlertModel: TextEditorRenameAlertModel)
        case stopLoading
        case startLoading
        case editFile
        case updateProgressView(progress: Float)
        case showError(message: String)
        case downloadToOffline
        case startDownload(status: String)
        case showDiscardChangeAlert
    }
    
    var invokeCommand: ((Command) -> Void)?
    private var router: TextEditorViewRouting
    private var textFile: TextFile
    private var textEditorMode: TextEditorMode
    private var parentHandle: MEGAHandle?
    private var nodeHandle: MEGAHandle?
    private var uploadFileUseCase: UploadFileUseCaseProtocol
    private var downloadFileUseCase: DownloadFileUseCaseProtocol
    private var nodeActionUseCase: NodeActionUseCaseProtocol
    private var shouldEditAfterOpen: Bool = false
    private var showErrorWhenToSetupView: Command?
    
    init(
        router: TextEditorViewRouting,
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        uploadFileUseCase: UploadFileUseCaseProtocol,
        downloadFileUseCase: DownloadFileUseCaseProtocol,
        nodeActionUseCase: NodeActionUseCaseProtocol,
        parentHandle: MEGAHandle? = nil,
        nodeHandle: MEGAHandle? = nil
    ) {
        self.router = router
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.uploadFileUseCase = uploadFileUseCase
        self.downloadFileUseCase = downloadFileUseCase
        self.nodeActionUseCase = nodeActionUseCase
        self.parentHandle = parentHandle
        self.nodeHandle = nodeHandle
    }
    
    func dispatch(_ action: TextEditorViewAction) {
        switch action {
        case .setUpView:
            setupView(shallUpdateContent: true)
        case .saveText(let content):
            saveText(content: content)
        case .renameFile:
            invokeCommand?(.showRenameAlert(makeTextEditorRenameAlertModel()))
        case .renameFileTo(let newInputName):
            renameFileTo(newInputName: newInputName)
        case .uploadFile:
            uploadFile()
        case .dismissTextEditorVC:
            router.dismissTextEditorVC()
        case .editFile:
            editFile(shallUpdateContent: false)
        case .editAfterOpen:
            editAfterOpen()
        case .showActions(sender: let button):
            router.showActions(sender: button)
        case .cancelText(let content):
            cancelText(content: content)
        case .cancel:
            cancel()
        case .downloadToOffline:
            downloadToOffline()
        case .importNode:
            router.importNode(nodeHandle: nodeHandle)
        case .share(sender: let button):
            router.share(nodeHandle: nodeHandle, sender: button)
        }
        
    }
    
    //MARK: - Private functions
    private func setupView(shallUpdateContent:Bool) {
        if textEditorMode == .load {
            invokeCommand?(.setupLoadViews)
            invokeCommand?(.configView(makeTextEditorModel(), shallUpdateContent: false))
            invokeCommand?(.setupNavbarItems(makeNavbarItemsModel()))
            downloadToTempFolder()
        } else {
            invokeCommand?(.configView(makeTextEditorModel(), shallUpdateContent: shallUpdateContent))
            invokeCommand?(.setupNavbarItems(makeNavbarItemsModel()))
        }
        
        if let command = showErrorWhenToSetupView {
            invokeCommand?(command)
            showErrorWhenToSetupView = nil
        }
    }
    
    private func saveText(content: String) {
        textFile.content = content
        if textEditorMode == .edit {
            invokeCommand?(.startLoading)
            uploadFile()
        } else if textEditorMode == .create {
            if let parentHandle = parentHandle {
                uploadTo(parentHandle)
            } else {
                router.chooseParentNode { (parentHandle) in
                    self.uploadTo(parentHandle)
                }
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
    
    private func renameFileTo(newInputName: String) {
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
            try content.write(toFile: tempPath, atomically: true, encoding: String.Encoding(rawValue: textFile.encode))
            uploadFileUseCase.uploadFile(withLocalPath: tempPath, toParent: parentHandle) { (result) in
                if self.textEditorMode == .edit {
                    self.invokeCommand?(.stopLoading)
                }
                
                switch result {
                case .failure(_):
                    self.invokeCommand?(.showError(message: TextEditorL10n.transferError + " " + TextEditorL10n.upload))
                case .success(_):
                    if self.textEditorMode == .edit {
                        self.textEditorMode = .view
                        self.setupView(shallUpdateContent: false)
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
    
    private func editFile(shallUpdateContent: Bool) {
        if textFile.size < TextFile.maxEditableFileSize {
            textEditorMode = .edit
            setupView(shallUpdateContent: shallUpdateContent)
        } else {
            if invokeCommand != nil {
                invokeCommand?(.showError(message: TextEditorL10n.uneditableLargeFileMessage))
            } else {
                showErrorWhenToSetupView = .showError(message: TextEditorL10n.uneditableLargeFileMessage)
            }
        }
    }
    
    private func editAfterOpen() {
        if textEditorMode == .view {
            editFile(shallUpdateContent: true)
        } else if textEditorMode == .load {
            shouldEditAfterOpen = true
        }
    }
    
    private func cancelText(content: String) {
        if content != textFile.content {
            invokeCommand?(.showDiscardChangeAlert)
        } else {
            cancel()
        }
    }
    
    private func cancel() {
        if textEditorMode == .create {
            router.dismissTextEditorVC()
        } else if textEditorMode == .edit{
            textEditorMode = .view
            self.setupView(shallUpdateContent: true)
        }
    }
    
    private func downloadToOffline() {
        invokeCommand?(.startDownload(status: TextEditorL10n.downloadMessage))
        guard let nodeHandle = nodeHandle else { return }
        nodeActionUseCase.downloadToOffline(nodeHandle: nodeHandle)
    }
    
    private func downloadToTempFolder() {
        guard let nodeHandle = nodeHandle else { return }
        downloadFileUseCase.downloadToTempFolder(nodeHandle: nodeHandle) { (transferEntity) in
            guard let transferredBytes = transferEntity.transferredBytes,
                  let totalBytes = transferEntity.totalBytes
            else { return }
            let percentage = transferredBytes / totalBytes
            self.invokeCommand?(.updateProgressView(progress: percentage))
        } completion: { (result) in
            switch result {
            case .failure(_):
                self.invokeCommand?(.showError(message: TextEditorL10n.transferError + " " + TextEditorL10n.download))
            case .success(let transferEntity):
                guard let path = transferEntity.path else { return }
                do {
                    var encode: String.Encoding = .utf8
                    self.textFile.content = try String(contentsOfFile: path, usedEncoding: &encode)
                    self.textFile.encode = encode.rawValue
                    if self.shouldEditAfterOpen {
                        self.editFile(shallUpdateContent: true)
                        self.shouldEditAfterOpen = false
                    } else {
                        self.textEditorMode = .view
                        self.setupView(shallUpdateContent: true)
                    }
                } catch {
                    self.router.showPreviewDocVC(fromFilePath: path)
                }
            }
        }
    }
    
    private func makeTextEditorModel() -> TextEditorModel {
        switch textEditorMode {
        case .view:
            return TextEditorModel(
                textFile: textFile,
                textEditorMode: textEditorMode,
                accessLevel: nodeAccessLevel()
            )
        case .load,
             .edit,
             .create:
            return TextEditorModel(
                textFile: textFile,
                textEditorMode: textEditorMode,
                accessLevel: nil
            )
        }
    }
    
    private func makeNavbarItemsModel() -> TextEditorNavbarItemsModel {
        switch textEditorMode {
        case .load:
            return TextEditorNavbarItemsModel (
                leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
                rightItem: nil,
                textEditorMode: textEditorMode
            )
            case .view:
            return TextEditorNavbarItemsModel (
                leftItem: NavbarItemModel(title: TextEditorL10n.close, imageName: nil),
                rightItem: NavbarItemModel(title: nil, imageName: "moreSelected"),
                textEditorMode: textEditorMode
            )
        case .edit,
             .create:
            return TextEditorNavbarItemsModel (
                leftItem: NavbarItemModel(title: TextEditorL10n.cancel, imageName: nil),
                rightItem: NavbarItemModel(title: TextEditorL10n.save, imageName: nil),
                textEditorMode: textEditorMode
            )
        }
    }
    
    private func nodeAccessLevel() -> NodeAccessTypeEntity {
        guard let nodeHandle = nodeHandle else {
            return .unknown
        }
        return nodeActionUseCase.nodeAccessLevel(nodeHandle: nodeHandle)
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
