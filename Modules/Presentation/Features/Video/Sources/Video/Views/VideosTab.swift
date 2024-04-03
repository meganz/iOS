import MEGAL10n

public enum VideosTab: CaseIterable {
    case all
    case playlist
    
    var title: String {
        switch self {
        case .all:
            return Strings.Localizable.Videos.Tab.Title.all
        case .playlist:
            return Strings.Localizable.Videos.Tab.Title.playlist
        }
    }
}
