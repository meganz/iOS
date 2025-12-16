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
            Strings.Localizable.CameraUploads.Timeline.title
        case .album:
            Strings.Localizable.CameraUploads.Albums.title
        case .video:
            Strings.Localizable.Videos.Navigationbar.title
        case .playlist:
            Strings.Localizable.Videos.Tab.Title.playlist
        }
    }
}
