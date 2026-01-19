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
            Image(uiImage: MEGAAssets.UIImage.import)
        case .makeAvailableOffline:
            Image(uiImage: MEGAAssets.UIImage.offline)
        case .saveToPhotos:
            Image(uiImage: MEGAAssets.UIImage.saveToPhotos)
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
