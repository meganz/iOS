import MEGAAssets
import MEGAL10n
import SwiftUI

public enum HomeAddMenuAction: Sendable, Identifiable, CaseIterable {
    public var id: Self { self }
    case chooseFromPhotos, capture, importFromFiles, scanDocument, newTextFile, openLink, newChat

    var image: Image {
        switch self {
        case .chooseFromPhotos:
            MEGAAssets.Image.photosApp
        case .capture:
            MEGAAssets.Image.camera
        case .importFromFiles:
            MEGAAssets.Image.folderArrow
        case .scanDocument:
            MEGAAssets.Image.fileScan
        case .newTextFile:
            MEGAAssets.Image.filePlus02
        case .openLink:
            MEGAAssets.Image.link02MediumThinOutline
        case .newChat:
            MEGAAssets.Image.messageChatCircle
        }
    }

    var title: String {
        switch self {
        case .chooseFromPhotos:
            Strings.Localizable.choosePhotoVideo
        case .capture:
            Strings.Localizable.capturePhotoVideo
        case .importFromFiles:
            Strings.Localizable.CloudDrive.Upload.importFromFiles
        case .scanDocument:
            Strings.Localizable.scanDocument
        case .newTextFile:
            Strings.Localizable.newTextFile
        case .openLink:
            Strings.Localizable.OpenLink.title
        case .newChat:
            Strings.Localizable.Chat.NewChat.title
        }
    }
}
