import MEGADomain
import MEGADomainMock
@testable import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
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
    
    func testAlbumElementIds_notCached_shouldRetrieveAlbumElementIdsFromUserAlbumRepository() async {
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
                                     AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 65, nodeId: 87)]
        
        let userAlbumRepository = MockUserAlbumRepository(albumElementIds: [albumId: expectedAlbumPhotoIds])
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        let albumPhotoIds = await sut.albumElementIds(by: albumId, includeElementsInRubbishBin: false)
        
        XCTAssertEqual(albumPhotoIds, expectedAlbumPhotoIds)
    }
    
    func testAlbumElementIds_cachedElementIds_shouldReturnCachedValues() async {
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
                                     AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 65, nodeId: 87)]
        
        let userAlbumCache = MockUserAlbumCache(albumsElementIds: [albumId: expectedAlbumPhotoIds])
        
        let sut = makeSUT(userAlbumCache: userAlbumCache)
        
        let albumPhotoIds = await sut.albumElementIds(by: albumId, includeElementsInRubbishBin: false)
        
        XCTAssertEqual(albumPhotoIds, expectedAlbumPhotoIds)
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
    
    func testMonitorSetUpdates_onNewSetsAdded_shouldUpdateCacheWithNewSet() async {
        
        // Arrange
        let expectedResults = [SetEntity(handle: 123)]
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [])
        
        // Act
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)

        // Assert
        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { result in
                XCTAssertEqual(Set(result), Set(expectedResults))
                exp.fulfill()
            }
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResults)

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
    }
    
    func testMonitorSetUpdates_onNewSetsRemoved_shouldUpdateCacheWithRemovedSet() async {
        
        // Arrange
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 123)])
        
        // Act
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)

        // Assert
        let exp = expectation(description: "An empty result from publisher")
        let cancellable = sut.setsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { result in
                XCTAssertTrue(result.allSatisfy { $0.changeTypes == .removed })
                exp.fulfill()
            }
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: [SetEntity(handle: 123, changeTypes: .removed)])

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
    }
    
    func testMonitorSetUpdates_onNewSetNameChange_shouldUpdateCacheWithUpdatedSet() async {
        
        // Arrange
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 123, name: "Test 123")])
        
        // Act
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)

        // Assert
        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { result in
                XCTAssertEqual(result.map(\.name), ["Test 1234"])
                exp.fulfill()
            }
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: [SetEntity(handle: 123, name: "Test 1234", changeTypes: .name)])

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
    }
    
    func testMonitorSetElementUpdates_onSetElementRemoval_shouldInvalidateElementsInCacheForTheSet() async {
        
        // Arrange
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 65, nodeId: 87)
        ]
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(
            albums: [SetEntity(handle: albumId, name: "Test 123")],
            albumsElementIds: [albumId: expectedAlbumPhotoIds])
        
        // Act
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)

        // Assert
        
        let initialResult = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(initialResult, expectedAlbumPhotoIds)

        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setElementsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { _ in exp.fulfill() }
        
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 65, ownerId: albumId, changeTypes: .removed)
            ])

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        
        let result = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertNil(result)
    }
    
    func testMonitorSetElementUpdates_onSetElementInsertion_shouldInvalidateElementsInCacheForTheSet() async {
        
        // Arrange
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 65, nodeId: 87)
        ]
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(
            albums: [SetEntity(handle: albumId, name: "Test 123")],
            albumsElementIds: [albumId: expectedAlbumPhotoIds])
        
        // Act
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)

        // Assert
        
        let initialResult = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(initialResult, expectedAlbumPhotoIds)

        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setElementsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { _ in exp.fulfill() }
        
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 65, ownerId: albumId, changeTypes: .new)
            ])

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        
        let result = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertNil(result)
    }
    
    func testMonitorSetElementUpdates_onSetElementNameChange_shouldInvalidateElementsInCacheForTheSet() async {
        
        // Arrange
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 65, nodeId: 87)
        ]
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(
            albums: [SetEntity(handle: albumId, name: "Test 123")],
            albumsElementIds: [albumId: expectedAlbumPhotoIds])
        
        // Act
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)

        // Assert
        
        let initialResult = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(initialResult, expectedAlbumPhotoIds)

        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setElementsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { _ in exp.fulfill() }
        
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 65, ownerId: albumId, name: "New Name", changeTypes: .name)
            ])

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        
        let result = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertNil(result)
    }
  
    func testAlbumUpdated_onSetUpdate_shouldUpdateCacheAndYieldUpdatedSets() async {
        
        let expectedResult = [
            SetEntity(handle: 1),
            SetEntity(handle: 3),
            SetEntity(handle: 6)
        ]
        
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache()
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let updatedExp = expectation(description: "update was emitted")
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        
        let task = Task {
            for await updatedSets in await sut.albumsUpdated() {
                XCTAssertEqual(Set(updatedSets), Set(expectedResult))
                updatedExp.fulfill()
            }
            taskFinishedExp.fulfill()
        }
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResult)
        
        await fulfillment(of: [updatedExp], timeout: 0.5)
        task.cancel()
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
    }
    
    func testAlbumUpdated_onSetUpdate_shouldUpdateCacheAndYieldUpdatedSetsToMultipleListeners() async {
        
        let expectedResult = [
            SetEntity(handle: 1),
            SetEntity(handle: 3),
            SetEntity(handle: 6)
        ]
        
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache()
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let numberOfSequences = 20
        let updatedExp = expectation(description: "update was emitted")
        updatedExp.expectedFulfillmentCount = numberOfSequences
        updatedExp.assertForOverFulfill = false
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        taskFinishedExp.expectedFulfillmentCount = numberOfSequences
        taskFinishedExp.assertForOverFulfill = false
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false
        
        let tasks = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await updatedSets in await sut.albumsUpdated() {
                        XCTAssertEqual(Set(updatedSets), Set(expectedResult))
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
          
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResult)
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
    }
    
    func testAlbumUpdatedForId_onSetUpdate_shouldYieldUpdatedSetsToMultipleListenersForGivenSetOnly() async {
        
        let expectedResult = SetEntity(handle: 3)
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache()
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let numberOfSequences = 20
        let updatedExp = expectation(description: "update was emitted")
        updatedExp.expectedFulfillmentCount = numberOfSequences
        updatedExp.assertForOverFulfill = false
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        taskFinishedExp.expectedFulfillmentCount = numberOfSequences
        taskFinishedExp.assertForOverFulfill = false
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false
        
        let tasks = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await updatedSet in await sut.albumUpdated(by: 3) {
                        XCTAssertEqual(updatedSet, expectedResult)
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
          
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: [
            SetEntity(handle: 1),
            expectedResult,
            SetEntity(handle: 6)
        ])
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
    }
    
    func testAlbumUpdatedForId_onSetUpdateForSetNotBeingMonitored_shouldNotYieldUpdatedSetsToMultipleListeners() async {
        
        let expectedResult = [
            SetEntity(handle: 1),
            SetEntity(handle: 3),
            SetEntity(handle: 6)
        ]
        
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache()
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let numberOfSequences = 20
        let updatedExp = expectation(description: "expecting no update for set that is not being monitored for a change")
        updatedExp.isInverted = true
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        taskFinishedExp.expectedFulfillmentCount = numberOfSequences
        taskFinishedExp.assertForOverFulfill = false
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false
        
        let tasks = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await _ in await sut.albumUpdated(by: 4) {
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
          
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResult)
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
    }
    
    func testAlbumUpdatedForId_onSetUpdateAndUpdateContainsRemoveChange_shouldYieldNilUpdateToMultipleListeners() async {
        
        let expectedResult = [
            SetEntity(handle: 1),
            SetEntity(handle: 3, changeTypes: .removed),
            SetEntity(handle: 6)
        ]
        
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 3)])
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let numberOfSequences = 20
        let updatedExp = expectation(description: "expecting no update for set that is not being monitored for a change")
        updatedExp.expectedFulfillmentCount = numberOfSequences
        updatedExp.assertForOverFulfill = false
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        taskFinishedExp.expectedFulfillmentCount = numberOfSequences
        taskFinishedExp.assertForOverFulfill = false
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false
        
        let tasks = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await setUpdate in await sut.albumUpdated(by: 3) {
                        XCTAssertNil(setUpdate)
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
          
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResult)
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
    }
    
    func testAlbumContentUpdatedForId_onSetElementUpdate_shouldYieldUpdateToMultipleListeners() async {
        let albumId: HandleEntity = 3
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 3)])
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let numberOfSequences = 20
        let updatedExp = expectation(description: "expecting update for set elements for the monitored change")
        updatedExp.expectedFulfillmentCount = numberOfSequences
        updatedExp.assertForOverFulfill = false
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        taskFinishedExp.expectedFulfillmentCount = numberOfSequences
        taskFinishedExp.assertForOverFulfill = false
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false
        
        let tasks = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await _ in await sut.albumContentUpdated(by: albumId, includeElementsInRubbishBin: false) {
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
          
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 1, ownerId: albumId)
            ])
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
    }
    
    func testAlbumContentUpdatedForId_onSetElementUpdateAndChangeOccuredForUnmonitoredSet_shouldNotYieldUpdateToMultipleListeners() async {
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 3)])
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let numberOfSequences = 20
        let updatedExp = expectation(description: "expecting no update for set elements for the monitored change")
        updatedExp.isInverted = true
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        taskFinishedExp.expectedFulfillmentCount = numberOfSequences
        taskFinishedExp.assertForOverFulfill = false
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        expectedTasksStarted.expectedFulfillmentCount = numberOfSequences
        expectedTasksStarted.assertForOverFulfill = false
        
        let tasks = (0..<numberOfSequences)
            .map { _ in
                Task {
                    expectedTasksStarted.fulfill()
                    for await _ in await sut.albumContentUpdated(by: 2, includeElementsInRubbishBin: false) {
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
          
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 1, ownerId: 1)
            ])
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        userAlbumCache: some UserAlbumCacheProtocol = MockUserAlbumCache(),
        setAndElementsUpdatesProvider: some SetAndElementUpdatesProviderProtocol = MockSetAndElementUpdatesProvider()
    ) -> UserAlbumCacheRepository {
        UserAlbumCacheRepository(userAlbumRepository: userAlbumRepository,
                                 userAlbumCache: userAlbumCache,
                                 setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
    }
}

extension AlbumElementsResultEntity: Equatable {
    public static func == (lhs: AlbumElementsResultEntity, rhs: AlbumElementsResultEntity) -> Bool {
        lhs.success == rhs.success && lhs.failure == rhs.failure
    }
}
