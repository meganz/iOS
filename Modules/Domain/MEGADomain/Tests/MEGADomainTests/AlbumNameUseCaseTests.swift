import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumNameUseCaseTests: XCTestCase {
    func testUserAlbumNames_onAlbumsLoaded_shouldReturnNames() async {
        let albums = [SetEntity(handle: 1, name: "Album 1"),
                      SetEntity(handle: 2, name: "Album 2")
        ]
        let userAlbumRepository = MockUserAlbumRepository(albums: albums)
        let sut = AlbumNameUseCase(userAlbumRepository: userAlbumRepository)
        
        let names = await sut.userAlbumNames()
        
        XCTAssertEqual(names, albums.map(\.name))
    }
}
