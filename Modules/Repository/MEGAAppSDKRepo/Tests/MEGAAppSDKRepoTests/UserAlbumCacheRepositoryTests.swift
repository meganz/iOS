import Combine
@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class UserAlbumCacheRepositoryTests: XCTestCase {
    func testAlbums_notPrimed_shouldRetrieveAlbumsFromUserAlbumRepositoryAndCacheIt() async {
        let albumCacheMonitorTaskManager = MockAlbumCacheMonitorTaskManager()
        let userAlbumCache = MockUserAlbumCache(albums: [])
        let albums = [SetEntity(handle: 12),
                      SetEntity(handle: 17)]
        let userAlbumRepository = MockUserAlbumRepository(albums: albums)
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCache: userAlbumCache,
                          albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)
        
        let result = await sut.albums()
        
        XCTAssertEqual(Set(result), Set(albums))
        
        let cachedValues = await userAlbumCache.albums
        XCTAssertEqual(Set(cachedValues), Set(albums))
        
        await assertTaskManager(albumCacheMonitorTaskManager)
    }
    
    func testAlbums_cachedAlbums_shouldReturn() async {
        let albums = [SetEntity(handle: 12),
                      SetEntity(handle: 17)]
        let userAlbumRepository = MockUserAlbumRepository(albums: albums)
        let userAlbumCache = MockUserAlbumCache()
        
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCache: userAlbumCache)
        
        let result = await sut.albums()
        
        XCTAssertEqual(Set(result), Set(albums))
        
        let afterPrimeResult = await sut.albums()
        XCTAssertEqual(Set(afterPrimeResult), Set(albums))
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
    
    func testAlbumElementIds_notCached_shouldRetrieveAlbumElementIdsFromUserAlbumRepository() async {
        let albumCacheMonitorTaskManager = MockAlbumCacheMonitorTaskManager()
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
                                     AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 65, nodeId: 87)]
        
        let userAlbumRepository = MockUserAlbumRepository(albumElementIds: [albumId: expectedAlbumPhotoIds])
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)
        
        let albumPhotoIds = await sut.albumElementIds(by: albumId, includeElementsInRubbishBin: false)
        
        XCTAssertEqual(albumPhotoIds, expectedAlbumPhotoIds)
        await assertTaskManager(albumCacheMonitorTaskManager)
    }
    
    func testAlbumElementIds_cachedElementIds_shouldReturnCachedValues() async throws {
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
                                     AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 65, nodeId: 87)]
        
        let userAlbumRepository = MockUserAlbumRepository(albumElementIds: [albumId: expectedAlbumPhotoIds])
        let userAlbumCache = MockUserAlbumCache()
        
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCache: userAlbumCache)
        
        let primedResult = await sut.albumElementIds(by: albumId, includeElementsInRubbishBin: false)
        let cachedValues = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        
        let expectedPhotoIds = Set(expectedAlbumPhotoIds)
        XCTAssertEqual(Set(primedResult), expectedPhotoIds)
        XCTAssertEqual(Set(try XCTUnwrap(cachedValues)), expectedPhotoIds)
        
        let cachedResult = await sut.albumElementIds(by: albumId, includeElementsInRubbishBin: false)
        XCTAssertEqual(Set(cachedResult), expectedPhotoIds)
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
    
    func testAlbumsUpdated_onSetUpdate_shouldYieldAllCachedAlbums() async throws {
        let albumCacheMonitorTaskManager = MockAlbumCacheMonitorTaskManager()
        let expectedResult = [SetEntity(handle: 1),
                              SetEntity(handle: 3),
                              SetEntity(handle: 6)]
        
        let userAlbumRepository = MockUserAlbumRepository(albums: expectedResult)
        
        let updates = [SetEntity(handle: 1)]
        
        let setUpdateAsyncSequences = SingleItemAsyncSequence(item: updates)
            .eraseToAnyAsyncSequence()
        
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors(
            setUpdateAsyncSequences: setUpdateAsyncSequences)
        
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCacheRepositoryMonitors: repositoryMonitor,
                          albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)
        
        var iterator = await sut.albumsUpdated().makeAsyncIterator()
        
        let updatedAlbums = await iterator.next()
        
        XCTAssertEqual(Set(try XCTUnwrap(updatedAlbums)), Set(expectedResult))
        await assertTaskManager(albumCacheMonitorTaskManager)
    }
    
    func testAlbumUpdatedForId_onSetUpdate_shouldYieldUpdatedSetsForGivenSetOnly() async {
        let albumId = HandleEntity(3)
        let expectedResult = SetEntity(handle: albumId)
        let userAlbumRepository = MockUserAlbumRepository(albums: [expectedResult])
        
        let updates = [
            SetEntity(handle: 1),
            expectedResult,
            SetEntity(handle: 6)]
        
        let setUpdateAsyncSequences = SingleItemAsyncSequence(item: updates)
            .eraseToAnyAsyncSequence()
        
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors(
            setUpdateAsyncSequences: setUpdateAsyncSequences)
        
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCacheRepositoryMonitors: repositoryMonitor)

        var iterator = await sut.albumUpdated(by: albumId).makeAsyncIterator()
        
        let updatedAlbum = await iterator.next()
        
        XCTAssertEqual(updatedAlbum, expectedResult)
    }
    
    func testAlbumUpdatedForId_onSetElementUpdateAlbumNotBeingMonitored_shouldNotYieldUpdated() async throws {
        let albumCacheMonitorTaskManager = MockAlbumCacheMonitorTaskManager()
        let updates = [
            SetEntity(handle: 1),
            SetEntity(handle: 3),
            SetEntity(handle: 6)]
        
        let setUpdateAsyncSequences = SingleItemAsyncSequence(item: updates)
            .eraseToAnyAsyncSequence()
        
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors(
            setUpdateAsyncSequences: setUpdateAsyncSequences)
        
        let sut = makeSUT(userAlbumCacheRepositoryMonitors: repositoryMonitor,
                          albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)

        var iterator = await sut.albumUpdated(by: 3).makeAsyncIterator()
        
        let updatedAlbum = await iterator.next()
        
        XCTAssertNil(try XCTUnwrap(updatedAlbum))
        await assertTaskManager(albumCacheMonitorTaskManager)
    }
    
    func testAlbumUpdatedForId_onSetUpdateAndUpdateContainsRemoveChange_shouldYieldNilUpdateToMultipleListeners() async throws {
        let albumId = HandleEntity(3)
        
        let updates = [
            SetEntity(handle: 1),
            SetEntity(handle: albumId, changeTypes: .removed),
            SetEntity(handle: 6)]
        
        let setUpdateAsyncSequences = SingleItemAsyncSequence(item: updates)
            .eraseToAnyAsyncSequence()
        
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors(
            setUpdateAsyncSequences: setUpdateAsyncSequences)
        
        let sut = makeSUT(userAlbumCacheRepositoryMonitors: repositoryMonitor)

        var iterator = await sut.albumUpdated(by: 3).makeAsyncIterator()
        
        let updatedAlbum = await iterator.next()
        
        XCTAssertNil(try XCTUnwrap(updatedAlbum))
    }
    
    func testAlbumContentUpdatedForId_onSetElementUpdate_shouldYieldUpdateToMultipleListeners() async {
        let albumId: HandleEntity = 3
        let updatedSets = [SetEntity(handle: albumId)]
        let expectedResult  = [SetElementEntity(handle: 1, ownerId: albumId)]
        let setElementUpdateOnSetsAsyncSequences = SingleItemAsyncSequence(item: updatedSets)
            .eraseToAnyAsyncSequence()
        let userAlbumRepository = MockUserAlbumRepository(albumContent: [albumId: expectedResult])
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors(
            setElementUpdateOnSetsAsyncSequences: setElementUpdateOnSetsAsyncSequences)
      
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCacheRepositoryMonitors: repositoryMonitor)

        var iterator = await sut.albumContentUpdated(by: albumId, includeElementsInRubbishBin: false).makeAsyncIterator()
        
        let updatedAlbum = await iterator.next()
        
        XCTAssertEqual(updatedAlbum, expectedResult)
    }
    
    func testAlbumContentUpdatedForId_onSetElementUpdateAndChangeOccuredForUnmonitoredSet_shouldNotYieldUpdate() async throws {
        let albumCacheMonitorTaskManager = MockAlbumCacheMonitorTaskManager()
        let updatedSets = [SetEntity(handle: 54)]
        let setElementUpdateOnSetsAsyncSequences = SingleItemAsyncSequence(item: updatedSets)
            .eraseToAnyAsyncSequence()
        
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors(
            setElementUpdateOnSetsAsyncSequences: setElementUpdateOnSetsAsyncSequences)
      
        let sut = makeSUT(userAlbumCacheRepositoryMonitors: repositoryMonitor,
                          albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)

        var iterator = await sut.albumContentUpdated(by: 45, includeElementsInRubbishBin: false).makeAsyncIterator()
        
        let updatedAlbum = await iterator.next()
        
        XCTAssertNil(updatedAlbum)
        await assertTaskManager(albumCacheMonitorTaskManager)
    }
    
    func testAlbumElementId_photoIdNotCached_shouldRetrieveAndCacheValue() async {
        let albumId = HandleEntity(67)
        let elementId = HandleEntity(877)
        let expected = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: elementId, nodeId: 77)
        
        let userAlbumRepository = MockUserAlbumRepository(albumElementIds: [albumId: [expected]])
        let userAlbumCache = MockUserAlbumCache()
        let sut = makeSUT(userAlbumRepository: userAlbumRepository, userAlbumCache: userAlbumCache)
        
        let result = await sut.albumElementId(by: albumId, elementId: elementId)
        
        XCTAssertEqual(result, expected)
        
        let cachedAlbumElementIds = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(cachedAlbumElementIds, [expected])
    }
    
    func testAlbumElementId_photoIdNotCachedAndItemNotFound_shouldReturnNil() async {
        let sut = makeSUT()
        
        let result = await sut.albumElementId(by: 7, elementId: 4)
        
        XCTAssertNil(result)
    }
    
    func testAlbumElementId_photoIdPrimed_shouldReturnCachedValue() async {
        let albumId = HandleEntity(67)
        let elementId = HandleEntity(877)
        let expected = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: elementId, nodeId: 77)
        
        let userAlbumRepository = MockUserAlbumRepository(albumElementIds: [albumId: [expected]])
        let userAlbumCache = MockUserAlbumCache()
        let sut = makeSUT(
            userAlbumRepository: userAlbumRepository,
            userAlbumCache: userAlbumCache)
        
        let result = await sut.albumElementId(by: albumId, elementId: elementId)
        
        XCTAssertEqual(result, expected)
    }
    
    func testEnsureCacheIsPrimedAfterInvalidationTaskStopped_onForcedCleared_shouldPrimeCache() async {
        let expectedAlbums = [SetEntity(handle: 12),
                              SetEntity(handle: 17)]
        let userAlbumRepository = MockUserAlbumRepository(albums: expectedAlbums)
        let userAlbumCache = MockUserAlbumCache(wasForcedCleared: true)
        let albumCacheMonitorTaskManager = MockAlbumCacheMonitorTaskManager(didChildTaskStop: false)
        
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCache: userAlbumCache,
                          albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)
        
        let albums = await sut.albums()
        
        XCTAssertEqual(Set(albums), Set(expectedAlbums))
        
        let cachedAlbums = await userAlbumCache.albums
        XCTAssertEqual(Set(cachedAlbums), Set(expectedAlbums))
        
        let wasForcedCleared = await userAlbumCache.wasForcedCleared
        XCTAssertFalse(wasForcedCleared)
    }
    
    func testEnsureCacheIsPrimedAfterInvalidation_onForcedClearedTaskNotStopped_shouldPrimeCache() async {
        let expectedAlbums = [SetEntity(handle: 12),
                              SetEntity(handle: 17)]
        let userAlbumRepository = MockUserAlbumRepository(albums: expectedAlbums)
        let userAlbumCache = MockUserAlbumCache(wasForcedCleared: true)
        let albumCacheMonitorTaskManager = MockAlbumCacheMonitorTaskManager(didChildTaskStop: false)
        
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          userAlbumCache: userAlbumCache,
                          albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)
        
        let albums = await sut.albums()
        
        XCTAssertEqual(Set(albums), Set(expectedAlbums))
        
        let cachedAlbums = await userAlbumCache.albums
        XCTAssertEqual(Set(cachedAlbums), Set(expectedAlbums))
        
        let wasForcedCleared = await userAlbumCache.wasForcedCleared
        XCTAssertFalse(wasForcedCleared)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        userAlbumCache: some UserAlbumCacheProtocol = MockUserAlbumCache(),
        userAlbumCacheRepositoryMonitors: some UserAlbumCacheRepositoryMonitorsProtocol = MockUserAlbumCacheRepositoryMonitors(),
        albumCacheMonitorTaskManager: some AlbumCacheMonitorTaskManagerProtocol = MockAlbumCacheMonitorTaskManager(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserAlbumCacheRepository {
        let sut = UserAlbumCacheRepository(
            userAlbumRepository: userAlbumRepository,
            userAlbumCache: userAlbumCache,
            userAlbumCacheRepositoryMonitors: userAlbumCacheRepositoryMonitors,
            albumCacheMonitorTaskManager: albumCacheMonitorTaskManager)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func assertTaskManager(_ taskManager: MockAlbumCacheMonitorTaskManager) async {
        let stopMonitoringCalled = await taskManager.stopMonitoringCalled
        XCTAssertEqual(stopMonitoringCalled, 1)
        let starMonitorCalled = await taskManager.startMonitoringCalled
        XCTAssertEqual(starMonitorCalled, 1)
    }
}

extension AlbumElementsResultEntity: @retroactive Equatable {
    public static func == (lhs: AlbumElementsResultEntity, rhs: AlbumElementsResultEntity) -> Bool {
        lhs.success == rhs.success && lhs.failure == rhs.failure
    }
}
