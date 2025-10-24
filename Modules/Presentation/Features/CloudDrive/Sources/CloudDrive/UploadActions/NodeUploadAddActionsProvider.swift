import MEGAAssets
import MEGADomain
import MEGAL10n

@MainActor
public protocol NodeUploadAddActionsHandlerProtocol: AnyObject, Sendable {
    func uploadAddMenu(didSelect action: UploadAddActionEntity)
}

public struct NodeUploadAddActionsProvider: Sendable {
    private let actionHandler: any NodeUploadAddActionsHandlerProtocol
    public var actions: [NodeUploadAction] {
        let chooseFromPhotosAction = NodeUploadAction(
            actionEntity: .chooseFromPhotos,
            image: MEGAAssets.Image.photosApp,
            title: Strings.Localizable.choosePhotoVideo) {
                actionHandler.uploadAddMenu(didSelect: .chooseFromPhotos)
            }

        let captureAction = NodeUploadAction(
            actionEntity: .capture,
            image: MEGAAssets.Image.camera,
            title: Strings.Localizable.capturePhotoVideo) {
                actionHandler.uploadAddMenu(didSelect: .capture)
            }

        let importFromAction = NodeUploadAction(
            actionEntity: .importFrom,
            image: MEGAAssets.Image.folderArrow,
            title: Strings.Localizable.CloudDrive.Upload.importFromFiles) {
                actionHandler.uploadAddMenu(didSelect: .importFrom)
            }

        let scanDocumentAction = NodeUploadAction(
            actionEntity: .scanDocument,
            image: MEGAAssets.Image.fileScan,
            title: Strings.Localizable.scanDocument) {
                actionHandler.uploadAddMenu(didSelect: .scanDocument)
            }

        let newFolderAction = NodeUploadAction(
            actionEntity: .newFolder,
            image: MEGAAssets.Image.folderPlus01,
            title: Strings.Localizable.newFolder) {
                actionHandler.uploadAddMenu(didSelect: .newFolder)
            }

        let newTextFileAction = NodeUploadAction(
            actionEntity: .newTextFile,
            image: MEGAAssets.Image.filePlus02,
            title: Strings.Localizable.newTextFile) {
                actionHandler.uploadAddMenu(didSelect: .newTextFile)
            }

        return [chooseFromPhotosAction, captureAction, importFromAction, scanDocumentAction, newFolderAction, newTextFileAction]
    }

    public init(actionHandler: some NodeUploadAddActionsHandlerProtocol) {
        self.actionHandler = actionHandler
    }
}
