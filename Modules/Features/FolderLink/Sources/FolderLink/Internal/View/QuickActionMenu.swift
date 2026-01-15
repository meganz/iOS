import MEGAAssets
import MEGAL10n
import SwiftUI

enum FolderLinkQuickAction: String, Identifiable {
    case importToCloudDrive
    case downloadToOffline
    case shareLink
    case sendToChat
    
    var id: Self { self }
}

extension FolderLinkQuickAction {
    var title: String {
        switch self {
        case .importToCloudDrive:
            Strings.Localizable.importToCloudDrive
        case .downloadToOffline:
            Strings.Localizable.General.downloadToOffline
        case .shareLink:
            Strings.Localizable.General.MenuAction.ShareLink.title(1)
        case .sendToChat:
            Strings.Localizable.General.sendToChat
        }
    }
    
    var icon: Image {
        switch self {
        case .importToCloudDrive:
            Image(uiImage: MEGAAssets.UIImage.import)
        case .downloadToOffline:
            Image(uiImage: MEGAAssets.UIImage.offline)
        case .shareLink:
            Image(uiImage: MEGAAssets.UIImage.link)
        case .sendToChat:
            Image(uiImage: MEGAAssets.UIImage.sendToChat)
        }
    }
}

struct QuickActionMenu: View {
    let quickActions: [FolderLinkQuickAction]
    @Binding var selection: FolderLinkQuickAction?
    
    var body: some View {
        ForEach(quickActions) { action in
            Button {
                selection = action
            } label: {
                Text(action.title)
                action.icon
            }
        }
    }
}
