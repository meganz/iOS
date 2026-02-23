import MEGAAssets
import MEGAL10n
import SwiftUI

struct BottomBarActionButton: View {
    let action: BottomBarAction
    @Binding var selection: BottomBarAction?

    var body: some View {
        Button {
            selection = action
        } label: {
            Label(title: { Text(action.title) }, icon: { action.icon })
        }
        .labelStyle(.iconOnly)
    }
}

private extension BottomBarAction {
    var title: String {
        switch self {
        case .download:
            Strings.Localizable.General.downloadToOffline
        case .removeFavourite:
            Strings.Localizable.removeFavourite
        case .shareLink:
            Strings.Localizable.Meetings.Panel.shareLink
        case .moveToRubbishBin:
            Strings.Localizable.General.MenuAction.moveToRubbishBin
        case .more:
            Strings.Localizable.more
        }
    }

    var icon: Image {
        switch self {
        case .download:
            Image(uiImage: MEGAAssets.UIImage.cloudDownload)
        case .removeFavourite:
            Image(uiImage: MEGAAssets.UIImage.heartBroken)
        case .shareLink:
            Image(uiImage: MEGAAssets.UIImage.link01)
        case .moveToRubbishBin:
            Image(uiImage: MEGAAssets.UIImage.trash)
        case .more:
            Image(uiImage: MEGAAssets.UIImage.moreHorizontal)
        }
    }
}
