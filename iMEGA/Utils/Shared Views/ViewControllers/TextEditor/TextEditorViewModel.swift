import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGASwift
import MEGATextEditor

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
    case exportFile(sender: Any)
    case editAfterOpen
    case updateReadingPosition(anchor: Int?, progress: Double)
    case saveReadingPosition
}

@objc enum TextEditorMode: Int, CaseIterable {
    case create
    case edit
    case view
    case load
}

@MainActor
protocol TextEditorViewRouting: Routing {
    func chooseParentNode(completion: @escaping (HandleEntity) -> Void)
    func dismissTextEditorVC()
    func dismissBrowserVC()
    func showActions(nodeHandle: HandleEntity, delegate: any NodeActionViewControllerDelegate, sender button: Any)
    func showPreviewDocVC(fromFilePath path: String, showUneditableError: Bool)
    func importNode(nodeHandle: HandleEntity?)
    func exportFile(from node: NodeEntity, sender button: Any)
    func showDownloadTransfer(node: NodeEntity)
    func sendToChat(node: MEGANode)
    func restoreTextFile(node: MEGANode)
    func viewInfo(node: MEGANode)
    func viewVersions(node: MEGANode)
    func removeTextFile(node: MEGANode)
    func shareLink(from nodeHandle: HandleEntity)
    func removeLink(from nodeHandle: HandleEntity)
    func hide(node: NodeEntity)
    func unhide(node: NodeEntity)
    func moveToRubbishBin(node: MEGANode)
}

final class TextEditorViewModel: ViewModelType {
    enum Command: CommandType, Equatable {
        case configView(_ textEditorModel: TextEditorModel, shallUpdateContent: Bool, isInRubbishBin: Bool, isBackupNode: Bool)
        case setupNavbarItems(_ navbarItemsModel: TextEditorNavbarItemsModel)
        case setupLoadViews
        case showDuplicateNameAlert(_ textEditorDuplicateNameAlertModel: TextEditorDuplicateNameAlertModel)
        case showRenameAlert(_ textEditorRenameAlertModel: TextEditorRenameAlertModel)
        case stopLoading
        case startLoading
        case editFile
        case updateProgressView(progress: Float)
        case showError(message: String)
        case showDiscardChangeAlert
    }
    
    var invokeCommand: ((Command) -> Void)?
    private var router: any TextEditorViewRouting
    private var textFile: TextFile
    private var textEditorMode: TextEditorMode
    private var parentHandle: HandleEntity?
    private var nodeEntity: NodeEntity?
    private var uploadFileUseCase: any UploadFileUseCaseProtocol
    private var downloadNodeUseCase: any DownloadNodeUseCaseProtocol
    private var nodeUseCase: any NodeUseCaseProtocol
    private var backupsUseCase: any BackupsUseCaseProtocol
    private var shouldEditAfterOpen: Bool = false
    private var showErrorWhenToSetupView: Command?
    private var isBackupNode: Bool = false
    private var downloadTask: Task<Void, any Error>?
    private let tracker: any AnalyticsTracking
    private let isMarkdownScreen: Bool
    /// A file from a folder link or a file link. The user does not own it, so the screen is read only.
    private let isLink: Bool
    private let resumeTextPositionUseCase: any ResumeTextPositionUseCaseProtocol
    private let leftOffItemRecordUseCase: any LeftOffItemRecordUseCaseProtocol
    /// Character offset of the top visible character. It is a position
    /// in the text, so it still points at the same words after a rotation or a font size change.
    private var readingAnchor: Int?

    /// How far down the laid out text the reader has scrolled, value ranges from 0 to 1.
    private var lastProgress: Double?

    init(
        router: some TextEditorViewRouting,
        textFile: TextFile,
        textEditorMode: TextEditorMode,
        uploadFileUseCase: any UploadFileUseCaseProtocol,
        downloadNodeUseCase: any DownloadNodeUseCaseProtocol,
        nodeUseCase: any NodeUseCaseProtocol,
        backupsUseCase: any BackupsUseCaseProtocol,
        resumeTextPositionUseCase: any ResumeTextPositionUseCaseProtocol,
        parentHandle: HandleEntity? = nil,
        nodeEntity: NodeEntity? = nil,
        isMarkdownScreen: Bool = false,
        isLink: Bool = false,
        leftOffItemRecordUseCase: some LeftOffItemRecordUseCaseProtocol = LeftOffItemsRecordUseCase.shared,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.router = router
        self.textFile = textFile
        self.textEditorMode = textEditorMode
        self.uploadFileUseCase = uploadFileUseCase
        self.downloadNodeUseCase = downloadNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.backupsUseCase = backupsUseCase
        self.resumeTextPositionUseCase = resumeTextPositionUseCase
        self.parentHandle = parentHandle
        self.nodeEntity = nodeEntity
        self.isMarkdownScreen = isMarkdownScreen
        self.isLink = isLink
        self.leftOffItemRecordUseCase = leftOffItemRecordUseCase
        self.tracker = tracker
    }

    /// The Markdown screens are on when the Markdown editor remote feature flag is on.
    static func isMarkdownEditorEnabled(
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) -> Bool {
        remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosMarkdownEditor)
    }
    
    func dispatch(_ action: TextEditorViewAction) {
        switch action {
        case .setUpView:
            if let nodeEntity {
                isBackupNode = backupsUseCase.isBackupNode(nodeEntity)
            }
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
            tracker.trackAnalyticsEvent(with: TextEditorCloseMenuToolbarEvent())
            saveReadingPosition()
            router.dismissTextEditorVC()
        case .editFile:
            tracker.trackAnalyticsEvent(with: TextEditorEditMenuToolbarEvent())
            editFile(shallUpdateContent: false)
        case .editAfterOpen:
            editAfterOpen()
        case .showActions(sender: let button):
            guard let handle = nodeEntity?.handle else { return }
            router.showActions(nodeHandle: handle, delegate: self, sender: button)
        case .cancelText(let content):
            cancelText(content: content)
        case .cancel:
            cancel()
        case .downloadToOffline:
            downloadToOffline()
        case .importNode:
            router.importNode(nodeHandle: nodeEntity?.handle)
        case .exportFile(sender: let button):
            tracker.trackAnalyticsEvent(with: TextEditorExportFileMenuToolbarEvent())
            exportFile(sender: button)
        case .updateReadingPosition(let anchor, let progress):
            if let anchor { readingAnchor = anchor }
            lastProgress = progress
        case .saveReadingPosition:
            processLeftOffItem()
            saveReadingPosition()
        }
    }
    
    // MARK: - Private functions
    private func setupView(shallUpdateContent: Bool) {
        tracker.trackAnalyticsEvent(with: TextEditorScreenEvent())

        var isNodeInRubbishBin = false
        if let nodeHandle = nodeEntity?.handle {
            isNodeInRubbishBin = nodeUseCase.isInRubbishBin(nodeHandle: nodeHandle)
        }
        
        if textEditorMode == .load {
            invokeCommand?(.setupLoadViews)
            invokeCommand?(.configView(makeTextEditorModel(), shallUpdateContent: false, isInRubbishBin: isNodeInRubbishBin, isBackupNode: isBackupNode))
            invokeCommand?(.setupNavbarItems(makeNavbarItemsModel()))
            downloadToTempFolder()
        } else {
            invokeCommand?(.configView(makeTextEditorModel(), shallUpdateContent: shallUpdateContent, isInRubbishBin: isNodeInRubbishBin, isBackupNode: isBackupNode))
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
            alertTitle: Strings.Localizable.rename,
            alertMessage: Strings.Localizable.renameNodeMessage,
            cancelButtonTitle: Strings.Localizable.cancel,
            renameButtonTitle: Strings.Localizable.rename,
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
        let tempUrl = uploadFileUseCase.tempURL(forFilename: fileName)
        do {
            try content.write(toFile: tempUrl.path, atomically: true, encoding: String.Encoding(rawValue: textFile.encode))
            let uploadOptions = UploadOptionsEntity(isSourceTemporary: false, pitagTarget: .cloudDrive)
            uploadFileUseCase.uploadFile(
                tempUrl,
                toParent: parentHandle,
                uploadOptions: uploadOptions,
                start: nil,
                progress: nil
            ) { result in
                if self.textEditorMode == .edit {
                    self.invokeCommand?(.stopLoading)
                }
                
                switch result {
                case .failure:
                    self.invokeCommand?(.showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.upload))
                case .success(let transfer):
                    // after a successful upload (aka file was edited), the old reading position is
                    // stale therefore we need to delete it.
                    self.deleteReadingPosition()
                    let previousHandle = self.nodeEntity?.handle
                    if let node = self.uploadFileUseCase.nodeForHandle(transfer.nodeHandle) {
                        self.nodeEntity = node
                    }
                    // An edit creates a new node, so the entry stored under the old handle would
                    // show up as a second row for the same file.
                    if let previousHandle, previousHandle != self.nodeEntity?.handle {
                        Task { [leftOffItemRecordUseCase = self.leftOffItemRecordUseCase] in
                            await leftOffItemRecordUseCase.remove(handle: previousHandle)
                        }
                    }
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
            MEGALogDebug("Could not write to file \(tempUrl) with error \(error.localizedDescription)")
        }
    }
    
    private func editFile(shallUpdateContent: Bool) {
        tracker.trackAnalyticsEvent(with: EditTextFileActionEvent())
        if textFile.size < TextFile.maxEditableFileSize {
            textEditorMode = .edit
            setupView(shallUpdateContent: shallUpdateContent)
        } else {
            if invokeCommand != nil {
                invokeCommand?(.showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile))
            } else {
                showErrorWhenToSetupView = .showError(message: Strings.Localizable.General.TextEditor.Hud.uneditableLargeFile)
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
        } else if textEditorMode == .edit {
            textEditorMode = .view
            self.setupView(shallUpdateContent: true)
        }
        downloadTask?.cancel()
    }
    
    private func downloadToOffline() {
        guard let nodeEntity = nodeEntity else {
            return
        }
        
        tracker.trackAnalyticsEvent(with: TextEditorMakeAvailableOfflineMenuToolbarEvent())
        router.showDownloadTransfer(node: nodeEntity)
    }
    
    private func downloadToTempFolder() {
        guard let nodeEntity else { return }
        
        downloadTask?.cancel()
        downloadTask = Task { @MainActor in
            do {
                let downloadStream = try downloadNodeUseCase.downloadFileToTempFolder(
                    node: nodeEntity,
                    appData: nil
                )
                
                for await event in downloadStream {
                    guard !Task.isCancelled else { return }
                    switch event {
                    case .update(let transferEntity):
                        handleDownloadInProgress(transferEntity)
                    case .finish(let transferEntity):
                        handleDownloadCompletion(transferEntity)
                    default:
                        break
                    }
                
                }
            } catch {
                invokeCommand?(.showError(message: Strings.Localizable.transferFailed + " " + Strings.Localizable.download))
            }
        }
    }
    
    private func handleDownloadInProgress(_ transferEntity: TransferEntity) {
        let percentage = Float(transferEntity.transferredBytes) / Float(transferEntity.totalBytes)
        invokeCommand?(.updateProgressView(progress: percentage))
    }
    
    private func handleDownloadCompletion(_ transferEntity: TransferEntity) {
        guard let path = transferEntity.path else { return }
        guard FileExtensionGroupOCWrapper.verify(isEditableTextFileAtPath: path) else {
            router.showPreviewDocVC(fromFilePath: path, showUneditableError: shouldEditAfterOpen)
            return
        }
        do {
            var encode: String.Encoding = .utf8
            if isMarkdownScreen {
                // The Markdown views need valid UTF-8. Other bytes go to the document preview, like any file that does not decode.
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                guard let text = MarkdownTextEditorText.decode(data) else {
                    router.showPreviewDocVC(fromFilePath: path, showUneditableError: shouldEditAfterOpen)
                    return
                }
                textFile.content = text
            } else {
                textFile.content = try String(contentsOfFile: path, usedEncoding: &encode)
            }
            textFile.encode = encode.rawValue
            if shouldEditAfterOpen {
                editFile(shallUpdateContent: true)
                shouldEditAfterOpen = false
            } else {
                textEditorMode = .view
                setupView(shallUpdateContent: true)
            }
        } catch {
            router.showPreviewDocVC(fromFilePath: path, showUneditableError: shouldEditAfterOpen)
        }
    }
    
    private func makeTextEditorModel() -> TextEditorModel {
        switch textEditorMode {
        case .view:
            // We don't support reading position for markdown preview
            // therefore `resumeReadingOffset` should be nil for markdown.
            // currently `resumeReadingOffset` doesn't have any effect on markdown preview
            // but we still add the gate to strengthen the logic anyways

            let isMarkdown = textFile.fileName.fileExtensionGroup.isMarkdownText
            return TextEditorModel(
                textFile: textFile,
                textEditorMode: textEditorMode,
                accessLevel: nodeAccessLevel(),
                resumeReadingOffset: isMarkdown ? nil : readingAnchor ?? storedReadingOffset
            )
        case .load,
             .edit,
             .create:
            return TextEditorModel(
                textFile: textFile,
                textEditorMode: textEditorMode,
                accessLevel: nil,
                resumeReadingOffset: nil
            )
        }
    }

    // MARK: - Reading position

    private var storedReadingOffset: Int? {
        guard let nodeEntity else { return nil }
        return resumeTextPositionUseCase.readingOffset(for: nodeEntity)
    }

    /// The anchor says where to resume. The progress says how much of the laid out content has been
    /// seen, which is what the thresholds below mean.
    private func saveReadingPosition() {
        guard textEditorMode == .view,
              let nodeEntity,
              let anchor = readingAnchor,
              let progress = lastProgress else { return }

        guard progress > Constants.minimumSavedPosition,
              progress < Constants.endOfFilePosition else {
            // Outside the thresholds there is nothing worth resuming: the reader is back at the start
            // or has finished. Any earlier position is stale, so it has to go.
            resumeTextPositionUseCase.deleteReadingOffset(for: nodeEntity)
            return
        }

        resumeTextPositionUseCase.saveReadingOffset(anchor, for: nodeEntity)
    }

    private func deleteReadingPosition() {
        guard let nodeEntity else { return }
        readingAnchor = nil
        lastProgress = nil
        resumeTextPositionUseCase.deleteReadingOffset(for: nodeEntity)
    }

    // MARK: - Left off item

    private func processLeftOffItem() {
        // Home can only reopen files of the account, and a link file is not one.
        guard !isLink, textEditorMode == .view, let nodeEntity, !nodeEntity.name.isEmpty else { return }

        let nearCompletionFraction = 0.9
        // Where the reader stopped, which is the same point the resume position returns to.
        let shouldRecordLeftOffItem = (lastProgress ?? 0) < nearCompletionFraction
        let handle = nodeEntity.handle
        let name = nodeEntity.name

        Task { [leftOffItemRecordUseCase] in
            if shouldRecordLeftOffItem {
                await leftOffItemRecordUseCase.record(handle: handle, name: name)
            } else {
                await leftOffItemRecordUseCase.remove(handle: handle)
            }
        }
    }

    private enum Constants {
        static let minimumSavedPosition: Double = 0.1
        static let endOfFilePosition: Double = 0.95
    }
    
    private func makeNavbarItemsModel() -> TextEditorNavbarItemsModel {
        switch textEditorMode {
        case .load:
            return TextEditorNavbarItemsModel(
                leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
                rightItem: nil,
                textEditorMode: textEditorMode
            )
        case .view:
            // The node actions need a node of the account, so a link file has no More button.
            return TextEditorNavbarItemsModel(
                leftItem: NavbarItemModel(title: Strings.Localizable.close, image: nil),
                rightItem: isLink ? nil : NavbarItemModel(title: nil, image: MEGAAssets.UIImage.moreNavigationBar),
                textEditorMode: textEditorMode
            )
        case .edit,
             .create:
            return TextEditorNavbarItemsModel(
                leftItem: NavbarItemModel(title: Strings.Localizable.cancel, image: nil),
                rightItem: NavbarItemModel(title: Strings.Localizable.save, image: nil),
                textEditorMode: textEditorMode
            )
        }
    }
    
    private func nodeAccessLevel() -> NodeAccessTypeEntity {
        isBackupNode || isLink ? .read : nodeUseCase.nodeAccessLevel(nodeHandle: nodeEntity?.handle ?? .invalid)
    }
    
    private func uploadTo(_ parentHandle: HandleEntity) {
        self.parentHandle = parentHandle
        let isFileNameDuplicated = uploadFileUseCase.hasExistFile(name: textFile.fileName, parentHandle: parentHandle)
        if isFileNameDuplicated {
            invokeCommand?(.showDuplicateNameAlert(
                TextEditorDuplicateNameAlertModel(
                    alertTitle: Strings.Localizable.renameFileAlertTitle(textFile.fileName),
                    alertMessage: Strings.Localizable.thereIsAlreadyAFileWithTheSameName,
                    cancelButtonTitle: Strings.Localizable.cancel,
                    replaceButtonTitle: Strings.Localizable.replace,
                    renameButtonTitle: Strings.Localizable.rename)
            ))
        } else {
            uploadFile()
            router.dismissBrowserVC()
        }
    }
    
    private func exportFile(sender: Any) {
        guard let nodeEntity = nodeEntity else {
            return
        }
        
        router.exportFile(from: nodeEntity, sender: sender)
    }
}

extension TextEditorViewModel: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .editTextFile:
            tracker.trackAnalyticsEvent(with: TextEditorEditMenuItemEvent())
            editFile(shallUpdateContent: false)
        case .download:
            tracker.trackAnalyticsEvent(with: TextEditorMakeAvailableOfflineMenuItemEvent())
            router.showDownloadTransfer(node: node.toNodeEntity())
        case .import:
            router.importNode(nodeHandle: node.handle)
        case .sendToChat:
            tracker.trackAnalyticsEvent(with: TextEditorSendToChatMenuItemEvent())
            router.sendToChat(node: node)
        case .exportFile:
            tracker.trackAnalyticsEvent(with: TextEditorExportFileMenuItemEvent())
            exportFile(sender: sender)
        case .restore:
            router.restoreTextFile(node: node)
        case .info:
            router.viewInfo(node: node)
        case .viewVersions:
            router.viewVersions(node: node)
        case .remove:
            router.removeTextFile(node: node)
        case .shareLink:
            tracker.trackAnalyticsEvent(with: TextEditorShareLinkMenuItemEvent())
            router.shareLink(from: node.handle)
        case .manageLink:
            router.shareLink(from: node.handle)
        case .removeLink:
            router.removeLink(from: node.handle)
        case .hide:
            tracker.trackAnalyticsEvent(with: TextEditorHideNodeMenuItemEvent())
            router.hide(node: node.toNodeEntity())
        case .unhide:
            router.unhide(node: node.toNodeEntity())
        case .moveToRubbishBin:
            router.moveToRubbishBin(node: node)
        default:
            break
        }
    }
}
