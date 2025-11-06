@testable import ContentLibraries
import MEGADomain
import MEGAL10n
import Testing

@Suite("AlbumEntityType+Additions Tests")
struct AlbumEntityTypeAdditionsTests {
    
    @Suite("Calls to localizedAlbumName")
    struct LocalizedAlbumName {
        
        @Test("Album entity type should return correct localized string for type", arguments: [
            (AlbumEntityType.favourite, String?.some(Strings.Localizable.CameraUploads.Albums.Favourites.title)),
            (.gif, Strings.Localizable.CameraUploads.Albums.Gif.title),
            (.raw, Strings.Localizable.CameraUploads.Albums.Raw.title),
            (.user, nil)
        ])
        func localized(type: AlbumEntityType, expectedName: String?) async throws {
            #expect(type.localizedAlbumName == expectedName)
        }
    }
}
