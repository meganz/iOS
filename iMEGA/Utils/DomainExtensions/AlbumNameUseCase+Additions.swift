import MEGADomain
import MEGAL10n

extension AlbumNameUseCaseProtocol {
    func reservedAlbumNames() async -> [String] {
        var reservedNames = await userAlbumNames()
        reservedNames.append(contentsOf: [Strings.Localizable.CameraUploads.Albums.Favourites.title,
                                       Strings.Localizable.CameraUploads.Albums.Gif.title,
                                       Strings.Localizable.CameraUploads.Albums.Raw.title,
                                       Strings.Localizable.CameraUploads.Albums.MyAlbum.title,
                                       Strings.Localizable.CameraUploads.Albums.SharedAlbum.title])
        return reservedNames
    }
}
