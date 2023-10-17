import MEGADomain
import MEGADomainMock
@testable import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class UserAlbumCacheRepositoryTests: XCTestCase {
    func testAlbums_notCached_shouldRetrieveAlbumsFromUserAlbumRepository() async {
        let userAlbumCache = MockUserAlbumCache(albums: [])
        let albums = [SetEntity(handle: 12),
                      SetEntity(handle: 17)]
        let userAlbumRepository = MockUserAlbumRepository(albums: albums)
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCache: userAlbumCache)
        
        let result = await sut.albums()
        
        XCTAssertEqual(result, albums)
    }
    
    func testAlbums_cachedAlbums_shouldReturn() async {
        let albums = [SetEntity(handle: 12),
                      SetEntity(handle: 17)]
        let userAlbumCache = MockUserAlbumCache(albums: albums)
        
        let sut = makeSUT(userAlbumCache: userAlbumCache)
        
        let result = await sut.albums()
        
        XCTAssertEqual(Set(result), Set(albums))
    }
    
    func testAlbumContent_notCached_shouldRetrieveAlbumContentFromUserAlbumRepository() async {
        let albumId = HandleEntity(65)
        let content = [SetElementEntity(handle: 54),
                       SetElementEntity(handle: 65)]
        let userAlbumRepository = MockUserAlbumRepository(albumContent: [albumId: content])
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = await sut.albumContent(by: albumId, includeElementsInRubbishBin: false)
        
        XCTAssertEqual(result, content)
    }
    
    func testAlbumElement_notCached_shouldRetrieveAlbumElementFromUserAlbumRepository() async {
        let albumId = HandleEntity(65)
        let albumElementId = HandleEntity(76)
        let albumElement = SetElementEntity(handle: albumElementId)
        let userAlbumRepository = MockUserAlbumRepository(albumElement: albumElement)
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = await sut.albumElement(by: albumId, elementId: albumElementId)
        
        XCTAssertEqual(result, albumElement)
    }
    
    func testCreateAlbum_onSuccess_shouldReturnAlbumCreatedByUserAlbumRepository() async throws {
        let albumName = "album name"
        let album = SetEntity(handle: 54, name: albumName)
        let userAlbumRepository = MockUserAlbumRepository(createAlbumResult: .success(album))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.createAlbum(albumName)
        
        XCTAssertEqual(result, album)
    }
    
    func testUpdateAlbumName_onSuccess_shouldReturnUpdatedNameFromUserAlbumRepository() async throws {
        let albumName = "album name"
        let userAlbumRepository = MockUserAlbumRepository(updateAlbumNameResult: .success(albumName))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.updateAlbumName(albumName, 65)
        
        XCTAssertEqual(result, albumName)
    }
    
    func testDeleteAlbum_onSuccess_shouldReturnDeletedHandleFromUserAlbumRepository() async throws {
        let albumId = HandleEntity(92)
        let userAlbumRepository = MockUserAlbumRepository(deleteAlbumResult: .success(albumId))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.deleteAlbum(by: albumId)
        
        XCTAssertEqual(result, albumId)
    }
    
    func testAddPhotosToAlbum_onSuccess_shouldAddPhotosToAlbumFromUserAlbumRepository() async throws {
        let albumId = HandleEntity(92)
        let photos = [NodeEntity(handle: 43)]
        let expectedResult = AlbumElementsResultEntity(success: UInt(photos.count), failure: 0)
        let userAlbumRepository = MockUserAlbumRepository(addPhotosResult: .success(expectedResult))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.addPhotosToAlbum(by: albumId, nodes: photos)
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testUpdateAlbumElementName_onSuccess_updateElementNameFromUserAlbumRepositoryAndReturnNewName() async throws {
        let elementName = "New element name"
        let userAlbumRepository = MockUserAlbumRepository(updateAlbumElementNameResult: .success(elementName))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.updateAlbumElementName(albumId: 23,
                                                          elementId: 54,
                                                          name: elementName)
        
        XCTAssertEqual(result, elementName)
    }
    
    func testUpdateAlbumElementOrder_onSuccess_updateElementNameFromUserAlbumRepositoryAndReturnOrder() async throws {
        let elementOrder: Int64 = 43
        let userAlbumRepository = MockUserAlbumRepository(updateAlbumElementOrderResult: .success(elementOrder))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.updateAlbumElementOrder(albumId: 14,
                                                           elementId: 65,
                                                           order: elementOrder)
        
        XCTAssertEqual(result, elementOrder)
    }
    
    func testDeleteAlbumElements_onSuccess_deleteAlbumElementFromUserAlbumRepositoryAndReturnResult() async throws {
        let albumElementIds = [HandleEntity(4),
                               HandleEntity(54),
                               HandleEntity(76)]
        let albumElementResult = AlbumElementsResultEntity(success: UInt(albumElementIds.count),
                                                           failure: 0)
        let userAlbumRepository = MockUserAlbumRepository(deleteAlbumElementsResult: .success(albumElementResult))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.deleteAlbumElements(albumId: 43,
                                                       elementIds: albumElementIds)
        
        XCTAssertEqual(result, albumElementResult)
    }
    
    func testUpdateAlbumCover_onSuccess_updateAlbumCoverFromUserAlbumRepositoryAndReturnHandle() async throws {
        let elementId = HandleEntity(55)
        let userAlbumRepository = MockUserAlbumRepository(updateAlbumCoverResult: .success(elementId))
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.updateAlbumCover(for: 43, elementId: elementId)
        
        XCTAssertEqual(result, elementId)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        userAlbumCache: some UserAlbumCacheProtocol = MockUserAlbumCache()
    ) -> UserAlbumCacheRepository {
        UserAlbumCacheRepository(userAlbumRepository: userAlbumRepository,
                                            userAlbumCache: userAlbumCache)
    }
}

extension AlbumElementsResultEntity: Equatable {
    public static func == (lhs: AlbumElementsResultEntity, rhs: AlbumElementsResultEntity) -> Bool {
        lhs.success == rhs.success && lhs.failure == rhs.failure
    }
}
