import MEGAAssets
import MEGAL10n
import SwiftUI

extension FolderLinkBottomBarAction {
    var title: String {
        switch self {
        case .addToCloudDrive:
            Strings.Localizable.importToCloudDrive
        case .makeAvailableOffline:
            Strings.Localizable.General.downloadToOffline
        case .saveToPhotos:
            Strings.Localizable.saveToPhotos
        }
    }
    
    var icon: Image {
        switch self {
        case .addToCloudDrive:
            Image(uiImage: MEGAAssets.UIImage.folderArrow)
        case .makeAvailableOffline:
            Image(uiImage: MEGAAssets.UIImage.cloudDownload)
        case .saveToPhotos:
            Image(uiImage: MEGAAssets.UIImage.photosApp)
        }
    }
}

struct FolderLinkBottomBarActionButton: View {
    let action: FolderLinkBottomBarAction
    @Binding var selection: FolderLinkBottomBarAction?
    
    var body: some View {
        Button {
            selection = action
        } label: {
            Label(title: { Text(action.title) }, icon: { action.icon })
        }
        .labelStyle(.iconOnly)
    }
}
