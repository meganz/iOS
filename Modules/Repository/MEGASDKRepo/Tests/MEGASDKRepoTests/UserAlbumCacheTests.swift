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
}
