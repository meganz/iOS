import Foundation
import MEGAL10n

enum MediaTab: Int, CaseIterable, Identifiable, Hashable {
    case timeline = 0
    case album = 1
    case video = 2
    case playlist = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .timeline:
            return Strings.Localizable.CameraUploads.Timeline.title
        case .album:
            return Strings.Localizable.CameraUploads.Albums.title
        case .video:
            return "Videos"  // WIP: Replace with localized string
        case .playlist:
            return "Playlists"  // WIP: Replace with localized string
        }
    }
}
