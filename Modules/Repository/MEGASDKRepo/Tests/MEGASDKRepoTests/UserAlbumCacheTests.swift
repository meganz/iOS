import MEGADomain
@testable import MEGASDKRepo
import XCTest

final class UserAlbumCacheTests: XCTestCase {
    
    override func tearDown() async throws {
        try await super.tearDown()
        await UserAlbumCache.shared.removeAllCachedValues()
    }
    
    func testAlbums_albumsSet_shouldRetrieve() async {
        let sut = UserAlbumCache.shared
        let albums = [SetEntity(handle: 534),
                      SetEntity(handle: 654)]
        await sut.setAlbums(albums)
        
        let result = await sut.albums
        
        XCTAssertEqual(Set(result), Set(albums))
    }
    
    func testAlbumElementIds_onSet_shouldRetrieve() async throws {
        let sut = UserAlbumCache.shared
        let albumId = HandleEntity(65)
        let elementIds = [AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 56, nodeId: 65),
                          AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 665, nodeId: 976)]
        await sut.setAlbumElementIds(forAlbumId: albumId, elementIds: elementIds)
        
        let result = await sut.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(Set(try XCTUnwrap(result)), Set(elementIds))
    }
    
    func testAlbums_removeAlbums_shouldRemoveGivenAlbums() async {
        let sut = UserAlbumCache.shared
        let albums = [SetEntity(handle: 534),
                      SetEntity(handle: 654)]
        await sut.setAlbums(albums)
        
        let afterInsertedResult = await sut.albums
        
        XCTAssertEqual(Set(afterInsertedResult), Set(albums))
        
        await sut.remove(albums: [SetEntity(handle: 534)])
        
        let afterRemovedResult = await sut.albums

        XCTAssertEqual(afterRemovedResult.map(\.handle), [654])
    }
}
