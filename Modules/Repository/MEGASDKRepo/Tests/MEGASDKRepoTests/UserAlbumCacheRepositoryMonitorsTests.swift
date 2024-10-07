@preconcurrency import Combine
import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class UserAlbumCacheRepositoryMonitorsTests: XCTestCase {
    
    func testSetsUpdatedPublisher_onNewSetsAdded_shouldUpdateCacheWithNewSet() async {
        // Arrange
        let expectedResults = [SetEntity(handle: 123)]
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [])
        
        // Act
        let sut = makeSUT(
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider, userAlbumCache: userAlbumCache)
        
        // Assert
        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { result in
                XCTAssertEqual(Set(result), Set(expectedResults))
                exp.fulfill()
            }
        
        let taskStartedExp = expectation(description: "Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResults)
        
        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        monitorTask.cancel()
    }
    
    func testSetsUpdatedPublisher_onNewSetsRemoved_shouldUpdateCacheWithRemovedSet() async {
        // Arrange
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 123)])
        
        // Act
        let sut = makeSUT(
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider, userAlbumCache: userAlbumCache)
        
        // Assert
        let exp = expectation(description: "An empty result from publisher")
        let cancellable = sut.setsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { result in
                XCTAssertTrue(result.allSatisfy { $0.changeTypes == .removed })
                exp.fulfill()
            }
        
        let taskStartedExp = expectation(description: "Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: [SetEntity(handle: 123, changeTypes: .removed)])
        
        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        monitorTask.cancel()
    }
    
    func testSetsUpdatedPublisher_onNewSetNameChange_shouldUpdateCacheWithUpdatedSet() async {
        // Arrange
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 123, name: "Test 123")])
        
        // Act
        let sut = makeSUT(
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider, userAlbumCache: userAlbumCache)
        
        // Assert
        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { result in
                XCTAssertEqual(result.map(\.name), ["Test 1234"])
                exp.fulfill()
            }
        
        let taskStartedExp = expectation(description: "Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: [SetEntity(handle: 123, name: "Test 1234", changeTypes: .name)])
        
        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        monitorTask.cancel()
    }
    
    func testSetElementsUpdatedPublisher_onSetElementRemoval_shouldRemoveDeletedElementsOnlyInCacheForTheSet() async throws {
        
        // Arrange
        let albumId = HandleEntity(65)
        let expectedAlbumPhotoIds = [
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 54, nodeId: 4),
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 55, nodeId: 87)
        ]
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(
            albums: [SetEntity(handle: albumId, name: "Test 123")],
            albumsElementIds: [albumId: expectedAlbumPhotoIds])
        
        // Act
        let sut = makeSUT(
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider,
            userAlbumCache: userAlbumCache)
        
        // Assert
        let cachedAlbumsElementIds = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(Set(try XCTUnwrap(cachedAlbumsElementIds)), Set(expectedAlbumPhotoIds))
        
        let initialResult = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(Set(try XCTUnwrap(initialResult)), Set(expectedAlbumPhotoIds))
        
        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setElementsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { _ in exp.fulfill() }
        
        let taskStartedExp = expectation(description: "Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetElementUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        let deletedElement = SetElementEntity(handle: 55, ownerId: albumId, nodeId: 87, changeTypes: .removed)

        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [deletedElement])
        
        await fulfillment(of: [exp], timeout: 10)
        cancellable.cancel()
        
        let result = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(result, expectedAlbumPhotoIds.filter { $0.albumPhotoId != deletedElement.handle })
        monitorTask.cancel()
    }
    
    func testSetElementsUpdatedPublisher_onSetElementInsertion_shouldInsertElementsInCacheForTheSet() async throws {
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
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider,
            userAlbumCache: userAlbumCache)
        
        // Assert
        let cachedAlbumsElementIds = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(Set(try XCTUnwrap(cachedAlbumsElementIds)), Set(expectedAlbumPhotoIds))
        
        let initialResult = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(initialResult, expectedAlbumPhotoIds)
        
        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setElementsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { _ in exp.fulfill() }
        
        let taskStartedExp = expectation(description: "Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetElementUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        let insertedElements = [SetElementEntity(handle: 65, ownerId: albumId, nodeId: 99, changeTypes: .new)]
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: insertedElements)
        
        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        
        let result = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        let expectedUpdatedResult = expectedAlbumPhotoIds + insertedElements.toAlbumPhotoIdEntities()
        XCTAssertEqual(result, expectedUpdatedResult)
        monitorTask.cancel()
    }
    
    func testSetElementsUpdatedPublisher_onSetElementNameChange_noChangeToCacheApplied() async {
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
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider,
            userAlbumCache: userAlbumCache)
        
        // Assert
        
        let initialResult = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(initialResult, expectedAlbumPhotoIds)
        
        let exp = expectation(description: "A non-empty result from publisher")
        let cancellable = sut.setElementsUpdatedPublisher
            .first { $0.isNotEmpty }
            .sink { _ in exp.fulfill() }
        
        let taskStartedExp = expectation(description: "Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetElementUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 65, ownerId: albumId, name: "New Name", changeTypes: .name)
            ])
        
        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
        
        let result = await userAlbumCache.albumElementIds(forAlbumId: albumId)
        XCTAssertEqual(result, expectedAlbumPhotoIds)
        monitorTask.cancel()
    }
    
    func testSetUpdateAsyncSequences_onSetUpdate_shouldUpdateCacheAndYieldUpdatedSets() async {
        let expectedResult = [
            SetEntity(handle: 1),
            SetEntity(handle: 3),
            SetEntity(handle: 6)
        ]
        
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache()
        
        let sut = makeSUT(
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider,
            userAlbumCache: userAlbumCache)
        
        let expectedTasksStarted = expectation(description: "Expected number of tasks started")
        let updatedExp = expectation(description: "update was emitted")
        let taskFinishedExp = expectation(description: "Task successfully finished on cancellation")
        
        let task = Task {
            let sequence = await sut.setUpdateAsyncSequences
            expectedTasksStarted.fulfill()
            for await updatedSets in sequence {
                XCTAssertEqual(Set(updatedSets), Set(expectedResult))
                updatedExp.fulfill()
            }
            taskFinishedExp.fulfill()
        }
        
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        
        let taskStartedExp = expectation(description: "Monitor Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResult)
        await fulfillment(of: [updatedExp], timeout: 0.5)
        task.cancel()
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
        monitorTask.cancel()
    }
    
    func testSetUpdateAsyncSequences_onSetUpdate_shouldUpdateCacheAndYieldUpdatedSetsToMultipleListeners() async {
        let expectedResult = [
            SetEntity(handle: 1),
            SetEntity(handle: 3),
            SetEntity(handle: 6)
        ]
        
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache()
        let sut = makeSUT(
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider,
            userAlbumCache: userAlbumCache)
        
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
                    let sequence = await sut.setUpdateAsyncSequences
                    expectedTasksStarted.fulfill()
                    for await updatedSets in sequence {
                        XCTAssertEqual(Set(updatedSets), Set(expectedResult))
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
        
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        
        let taskStartedExp = expectation(description: "Monitor Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        setAndElementsUpdatesProvider.mockSendSetUpdate(setUpdate: expectedResult)
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
        monitorTask.cancel()
    }
    
    func testSetElementAsyncSequences_onSetElementUpdate_shouldYieldUpdateToMultipleListeners() async {
        let albumId: HandleEntity = 3
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let userAlbumCache = MockUserAlbumCache(albums: [SetEntity(handle: 3)])
        
        let sut = makeSUT(
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider,
            userAlbumCache: userAlbumCache)
        
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
                    let sequence = await sut.setElementUpdateAsyncSequences
                    expectedTasksStarted.fulfill()
                    for await _ in sequence {
                        updatedExp.fulfill()
                    }
                    taskFinishedExp.fulfill()
                }
            }
        
        await fulfillment(of: [expectedTasksStarted], timeout: 1)
        
        let taskStartedExp = expectation(description: "Monitor Task started")
        let monitorTask = Task {
            taskStartedExp.fulfill()
            await sut.monitorSetElementUpdates()
        }
        await fulfillment(of: [taskStartedExp], timeout: 1)
        
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 1, ownerId: albumId)
            ])
        await fulfillment(of: [updatedExp], timeout: 0.5)
        tasks.forEach { $0.cancel() }
        await fulfillment(of: [taskFinishedExp], timeout: 0.5)
        monitorTask.cancel()
    }
    
    func testMonitorCacheInvalidationTriggers_onLogoutEvent_shouldClearCaches() async throws {
        let albumsElements: [HandleEntity: [AlbumPhotoIdEntity]] = [
            12: [.init(albumId: 12, albumPhotoId: 54, nodeId: 4)],
            17: [.init(albumId: 17, albumPhotoId: 65, nodeId: 87)]
        ]
        let albums = albumsElements.keys.map { SetEntity(handle: $0) }
        let userAlbumCache = MockUserAlbumCache(
            albums: albums,
            albumsElementIds: albumsElements)
        let notificationCentre = NotificationCenter()
        
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            cacheInvalidationTrigger: CacheInvalidationTrigger(
                notificationCentre: notificationCentre,
                logoutNotificationName: .accountDidLogout,
                didReceiveMemoryWarningNotificationName: { .init("TestMemoryWarningOccurred") }
            ))
        
        let cacheClearExpectation = expectation(description: "Expect cache to be cleared")
        let publisher = await userAlbumCache.$removeAllCachedValuesCalledCount
        let subscription = publisher
            .first(where: { $0 == 1})
            .sink { _ in cacheClearExpectation.fulfill() }
        
        let exp = expectation(description: "Task started")
        let monitorTask = Task {
            exp.fulfill()
            await sut.monitorCacheInvalidationTriggers()
        }
        await fulfillment(of: [exp], timeout: 1)
        
        // Await for monitoring tasks to start
        try await Task.sleep(nanoseconds: 1_000_000_000 / 2)
        
        notificationCentre.post(name: .accountDidLogout, object: nil)
        
        await fulfillment(of: [cacheClearExpectation], timeout: 1)
        subscription.cancel()
        
        await withTaskGroup(of: Void.self) { taskGroup in
            // Check Albums are cleared
            taskGroup.addTask {
                let expectedClearedAlbums = await userAlbumCache.albums
                XCTAssertTrue(expectedClearedAlbums.isEmpty)
            }
            
            // Check Elements linked to albums are cleared
            albumsElements
                .keys
                .forEach { key in
                    taskGroup.addTask {
                        let expectedClearedElements = await userAlbumCache.albumElementIds(forAlbumId: key)
                        XCTAssertNil(expectedClearedElements, "Expected \(key) to not contain any elements in cache")
                    }
                }
        }
        monitorTask.cancel()
    }
    
    func testMonitorCacheInvalidationTriggers_onMemoryWarning_shouldClearCaches() async throws {
        let albumsElements: [HandleEntity: [AlbumPhotoIdEntity]] = [
            12: [.init(albumId: 12, albumPhotoId: 54, nodeId: 4)],
            17: [.init(albumId: 17, albumPhotoId: 65, nodeId: 87)]
        ]
        let albums = albumsElements.keys.map { SetEntity(handle: $0) }
        let userAlbumCache = MockUserAlbumCache(
            albums: albums,
            albumsElementIds: albumsElements)
        
        let notificationCentre = NotificationCenter()
        let memoryWarningNotification = Notification.Name("TestMemoryWarningOccurred")
        let sut = makeSUT(
            userAlbumCache: userAlbumCache,
            cacheInvalidationTrigger: CacheInvalidationTrigger(
                notificationCentre: notificationCentre,
                logoutNotificationName: .accountDidLogout,
                didReceiveMemoryWarningNotificationName: { memoryWarningNotification }))
        
        let cacheClearExpectation = expectation(description: "Expect cache to be cleared")
        let publisher = await userAlbumCache.$removeAllCachedValuesCalledCount
        let subscription = publisher
            .first(where: { $0 == 1})
            .sink { _ in cacheClearExpectation.fulfill() }
        
        let exp = expectation(description: "Task started")
        let monitorTask = Task {
            exp.fulfill()
            await sut.monitorCacheInvalidationTriggers()
        }
        await fulfillment(of: [exp], timeout: 1)
        
        // Await for monitoring tasks to start
        try await Task.sleep(nanoseconds: 1_000_000_000 / 2)
        
        notificationCentre.post(name: memoryWarningNotification, object: nil)
        
        await fulfillment(of: [cacheClearExpectation], timeout: 1)
        subscription.cancel()
        
        await withTaskGroup(of: Void.self) { taskGroup in
            // Check Albums are cleared
            taskGroup.addTask {
                let expectedClearedAlbums = await userAlbumCache.albums
                XCTAssertTrue(expectedClearedAlbums.isEmpty)
            }
            
            // Check Elements linked to albums are cleared
            albumsElements
                .keys
                .forEach { key in
                    taskGroup.addTask {
                        let expectedClearedElements = await userAlbumCache.albumElementIds(forAlbumId: key)
                        XCTAssertNil(expectedClearedElements, "Expected \(key) to not contain any elements in cache")
                    }
                }
        }
        monitorTask.cancel()
    }
    
    func testSetElementUpdateOnSetsAsyncSequences_onSetElementUpdate_shouldYieldUpdatedAlbums() async {
        let albumId = HandleEntity(86)
        let setAndElementsUpdatesProvider = MockSetAndElementUpdatesProvider()
        let album = MockMEGASet(handle: albumId, userId: 0, coverId: 1, type: .album)
        let sdk = MockSdk(megaSets: [album])
        
        let sut = makeSUT(
            sdk: sdk,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider)
        
        let startedExp = expectation(description: "Sequence retrieved")
        let updatedExp = expectation(description: "update was emitted")
        let finishedExp = expectation(description: "Task successfully finished on cancellation")
        
        let task = Task {
            let sequence = await sut.setElementUpdateOnSetsAsyncSequences
            startedExp.fulfill()
            for await updatedSets in sequence {
                XCTAssertEqual(updatedSets, [album.toSetEntity()])
                updatedExp.fulfill()
            }
            finishedExp.fulfill()
        }
        await fulfillment(of: [startedExp], timeout: 1)
        
        let monitorExp = expectation(description: "Monitor task started")
        let monitorTask = Task {
            monitorExp.fulfill()
            await sut.monitorSetElementUpdates()
        }
        await fulfillment(of: [monitorExp], timeout: 1)
        
        setAndElementsUpdatesProvider
            .mockSendSetElementUpdate(setElementUpdate: [
                .init(handle: 1, ownerId: albumId)
            ])
        await fulfillment(of: [updatedExp], timeout: 0.5)
        task.cancel()
        monitorTask.cancel()
        await fulfillment(of: [finishedExp], timeout: 0.5)
    }
    
    private func makeSUT(
        sdk: MEGASdk = MockSdk(),
        setAndElementsUpdatesProvider: some SetAndElementUpdatesProviderProtocol = MockSetAndElementUpdatesProvider(),
        userAlbumCache: some UserAlbumCacheProtocol = MockUserAlbumCache(),
        cacheInvalidationTrigger: CacheInvalidationTrigger = .init(
            notificationCentre: .default,
            logoutNotificationName: .accountDidLogout,
            didReceiveMemoryWarningNotificationName: { .init("TestMemoryWarningOccurred") })
    ) -> UserAlbumCacheRepositoryMonitors {
        UserAlbumCacheRepositoryMonitors(
            sdk: sdk,
            setAndElementsUpdatesProvider: setAndElementsUpdatesProvider,
            userAlbumCache: userAlbumCache,
            cacheInvalidationTrigger: cacheInvalidationTrigger)
    }
}
