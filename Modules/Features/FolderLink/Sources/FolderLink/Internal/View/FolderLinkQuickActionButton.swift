import MEGAAssets
import MEGAL10n
import SwiftUI

extension FolderLinkQuickAction {
    var title: String {
        switch self {
        case .addToCloudDrive:
            Strings.Localizable.importToCloudDrive
        case .makeAvailableOffline:
            Strings.Localizable.General.downloadToOffline
        case .sendToChat:
            Strings.Localizable.General.sendToChat
        }
    }
    
    var icon: Image {
        switch self {
        case .addToCloudDrive:
            Image(uiImage: MEGAAssets.UIImage.import)
        case .makeAvailableOffline:
            Image(uiImage: MEGAAssets.UIImage.offline)
        case .sendToChat:
            Image(uiImage: MEGAAssets.UIImage.sendToChat)
        }
    }
}

struct FolderLinkQuickActionButton: View {
    let action: FolderLinkQuickAction
    @Binding var selection: FolderLinkQuickAction?
    
    var body: some View {
        Button {
            selection = action
        } label: {
            Text(action.title)
            action.icon
        }
    }
}
