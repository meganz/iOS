import MEGAAssets
import MEGADomain
import MEGAL10n

public enum FloatingActionEntity: Sendable, CaseIterable {
    case chooseFromPhotos, capture, importFrom, scanDocument, newFolder, newTextFile, openLink
}

@MainActor
public protocol FloatingActionsHandlerProtocol: AnyObject, Sendable {
    func handle(action: FloatingActionEntity)
}

public struct FloatingActionsProvider: Sendable {
    private let actionHandler: any FloatingActionsHandlerProtocol
    public var actions: [FloatingAddAction] {
        let chooseFromPhotosAction = FloatingAddAction(
            image: MEGAAssets.Image.photosApp,
            title: Strings.Localizable.choosePhotoVideo) {
                actionHandler.handle(action: .chooseFromPhotos)
            }

        let captureAction = FloatingAddAction(
            image: MEGAAssets.Image.camera,
            title: Strings.Localizable.capturePhotoVideo) {
                actionHandler.handle(action: .capture)
            }

        let importFromAction = FloatingAddAction(
            image: MEGAAssets.Image.folderArrow,
            title: Strings.Localizable.CloudDrive.Upload.importFromFiles) {
                actionHandler.handle(action: .importFrom)
            }

        let scanDocumentAction = FloatingAddAction(
            image: MEGAAssets.Image.fileScan,
            title: Strings.Localizable.scanDocument) {
                actionHandler.handle(action: .scanDocument)
            }

        let newFolderAction = FloatingAddAction(
            image: MEGAAssets.Image.folderPlus01,
            title: Strings.Localizable.newFolder) {
                actionHandler.handle(action: .newFolder)
            }

        let newTextFileAction = FloatingAddAction(
            image: MEGAAssets.Image.filePlus02,
            title: Strings.Localizable.newTextFile) {
                actionHandler.handle(action: .newTextFile)
            }

        let openLinkAction = FloatingAddAction(
            image: MEGAAssets.Image.link02MediumThinOutline,
            title: Strings.Localizable.OpenLink.title) {
                actionHandler.handle(action: .openLink)
            }

        return [chooseFromPhotosAction, captureAction, importFromAction, scanDocumentAction, newFolderAction, newTextFileAction, openLinkAction]
    }

    public init(actionHandler: some FloatingActionsHandlerProtocol) {
        self.actionHandler = actionHandler
    }
}
