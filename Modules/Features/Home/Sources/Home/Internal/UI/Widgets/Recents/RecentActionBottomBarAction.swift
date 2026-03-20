import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI

enum RecentActionBottomBarAction: Hashable, Identifiable {
    var id: Self { self }
    
    case download
    case copy
    case move
    case shareLink
    case moveToRubbishBin

    func toNodesAction(handles: Set<HandleEntity>) -> NodesAction {
        switch self {
        case .download: .download(handles)
        case .copy: .copy(handles)
        case .move: .move(handles)
        case .shareLink: .shareLink(handles)
        case .moveToRubbishBin: .moveToRubbishBin(handles)
        }
    }

    var title: String {
        switch self {
        case .download: Strings.Localizable.General.downloadToOffline
        case .copy: Strings.Localizable.copy
        case .move: Strings.Localizable.move
        case .shareLink: Strings.Localizable.Meetings.Panel.shareLink
        case .moveToRubbishBin: Strings.Localizable.General.MenuAction.moveToRubbishBin
        }
    }

    var icon: Image {
        switch self {
        case .download: MEGAAssets.Image.cloudDownload
        case .copy: MEGAAssets.Image.copy01
        case .move: MEGAAssets.Image.moveMono
        case .shareLink: MEGAAssets.Image.link01
        case .moveToRubbishBin: MEGAAssets.Image.trash
        }
    }
}
