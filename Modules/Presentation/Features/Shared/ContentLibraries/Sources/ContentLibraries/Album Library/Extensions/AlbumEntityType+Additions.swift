import MEGADomain
import MEGAL10n

public extension AlbumEntityType {
    var localizedAlbumName: String? {
        switch self {
        case .favourite:
            Strings.Localizable.CameraUploads.Albums.Favourites.title
        case .gif:
            Strings.Localizable.CameraUploads.Albums.Gif.title
        case .raw:
            Strings.Localizable.CameraUploads.Albums.Raw.title
        default:
            nil
        }
    }
}
