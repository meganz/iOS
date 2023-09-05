@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import XCTest

final class AlbumNameUseCase_AdditionsTests: XCTestCase {

    func testReservedAlbumNames_onLoad_shouldIncludeCurrentUserAlbumNames() async {
        let albumName = "User Album name"
        let userAlbumRepository = MockUserAlbumRepository(albums: [SetEntity(handle: 1, name: albumName)])
        let sut = AlbumNameUseCase(userAlbumRepository: userAlbumRepository)
        
        let reservedNames = await sut.reservedAlbumNames()
        
        XCTAssertTrue(reservedNames.contains(albumName))
    }
    
    func testReservedAlbumNames_onLoad_shouldIncludeMegaReservedAlbumNames() async {
        let albumReserved: Set = [Strings.Localizable.CameraUploads.Albums.Favourites.title,
                        Strings.Localizable.CameraUploads.Albums.Gif.title,
                        Strings.Localizable.CameraUploads.Albums.Raw.title,
                        Strings.Localizable.CameraUploads.Albums.MyAlbum.title,
                        Strings.Localizable.CameraUploads.Albums.SharedAlbum.title]

        let sut = AlbumNameUseCase(userAlbumRepository: MockUserAlbumRepository())
        
        let reservedNames = await sut.reservedAlbumNames()
        
        XCTAssertTrue(Set(reservedNames).isSubset(of: albumReserved))
    }
}
