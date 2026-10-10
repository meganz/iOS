import MEGAAssets
import MEGAL10n
import SwiftUI

extension FolderLinkBottomBarAction {
    var title: String {
        switch self {
        case .makeAvailableOffline:
            Strings.Localizable.General.downloadToOffline
        case .downloadToFiles:
            Strings.Localizable.download
        case .addToCloudDrive:
            Strings.Localizable.Link.Button.saveToMega
        case .saveToPhotos:
            Strings.Localizable.saveToPhotos
        }
    }
    
    func icon(isLinkRevampEnabled: Bool) -> Image {
        switch self {
        case .makeAvailableOffline:
            Image(uiImage: MEGAAssets.UIImage.cloudDownload)
        case .downloadToFiles:
            Image(uiImage: MEGAAssets.UIImage.downloadToDisk)
        case .addToCloudDrive:
            Image(uiImage: isLinkRevampEnabled ? MEGAAssets.UIImage.uploadToCloud : MEGAAssets.UIImage.folderArrow)
        case .saveToPhotos:
            Image(uiImage: MEGAAssets.UIImage.photosApp)
        }
    }
}

struct FolderLinkBottomBarActionButton: View {
    let action: FolderLinkBottomBarAction
    /// The pre-revamp toolbar keeps the icons the rest of the pre-revamp folder link uses.
    var isLinkRevampEnabled = false
    @Binding var selection: FolderLinkBottomBarAction?
    
    var body: some View {
        Button {
            selection = action
        } label: {
            Label(title: { Text(action.title) }, icon: { action.icon(isLinkRevampEnabled: isLinkRevampEnabled) })
        }
        .labelStyle(.iconOnly)
    }
}
