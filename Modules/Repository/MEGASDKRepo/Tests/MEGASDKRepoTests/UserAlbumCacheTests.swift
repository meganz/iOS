import MEGADomain
@testable import MEGASDKRepo
import XCTest

final class UserAlbumCacheTests: XCTestCase {
    
    override func tearDown() async throws {
        try await super.tearDown()
        await UserAlbumCache.shared.removeAllCachedValues(forced: false)
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
    
    func testRemoveAllCachedValues_forced_shouldSetFlagAndClearCorrectly() async {
        let sut = UserAlbumCache.shared
        let albums = [SetEntity(handle: 534),
                      SetEntity(handle: 654)]
        await sut.setAlbums(albums)
        
        await sut.removeAllCachedValues(forced: true)
        
        let wasForcedCleared = await sut.wasForcedCleared
        XCTAssertTrue(wasForcedCleared)
        
        await sut.clearForcedFlag()
        
        let wasForcedFlagCleared = await sut.wasForcedCleared
        XCTAssertFalse(wasForcedFlagCleared)
    }
    
    func testRemoveAlbums_cachedAlbums_shouldBeRemoved() async {
        let albumId = HandleEntity(54)
        let albumElements = [AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 56, nodeId: 65),
                             AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 665, nodeId: 976)]
    
        let sut = UserAlbumCache.shared
        await sut.setAlbumElementIds(forAlbumId: albumId, elementIds: albumElements)
       
        await sut.removeElements(of: [albumId])
        
        let result = await sut.albumElementIds(forAlbumId: albumId)
        XCTAssertNil(result)
    }
}
