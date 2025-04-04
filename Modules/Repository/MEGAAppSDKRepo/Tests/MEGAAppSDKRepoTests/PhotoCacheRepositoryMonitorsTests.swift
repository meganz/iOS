@preconcurrency import Combine
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import MEGASwift
import XCTest

final class PhotoCacheRepositoryMonitorsTests: XCTestCase {
    
    func testPhotosUpdate_onNodeUpdate_shouldUpdateCacheAndYieldUpdatedPhotos() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let fileNode = MockNode(handle: 54, name: "3.pdf")
        let photoNode = MockNode(handle: 76, name: "1.jpg", changeType: .new)
        let updatedPhoto = MockNode(handle: 87, name: "test.jpg", changeType: .parent)
        let cachedPhoto = NodeEntity(handle: 4)
        let sdk = MockSdk(nodes: [fileNode, photoNode, updatedPhoto],
                          megaRootNode: MockNode(handle: 1))
        let photoLocalSource = MockPhotoLocalSource(photos: [cachedPhoto])
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(sdk: sdk,
                          nodeUpdatesProvider: nodeUpdatesProvider, photoLocalSource: photoLocalSource)
        
        let monitorTask = Task {
            await sut.monitorPhotoNodeUpdates()
        }
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let expectedPhotos = [photoNode.toNodeEntity(), updatedPhoto.toNodeEntity()]
        
        let nodeUpdates = [[fileNode.toNodeEntity()],
                           [],
                           expectedPhotos]
        let task = Task {
            started.fulfill()
            for await updatedPhotos in await sut.photosUpdatedAsyncSequence {
                XCTAssertEqual(Set(updatedPhotos), Set(expectedPhotos))
                let photoSourcePhotos = await photoLocalSource.photos
                XCTAssertEqual(Set(photoSourcePhotos), Set(expectedPhotos + [cachedPhoto]))
                iterated.fulfill()
            }
            finished.fulfill()
        }
        await fulfillment(of: [started], timeout: 0.5)
        nodeUpdates.forEach {
            continuation.yield($0)
        }
        continuation.finish()
        await fulfillment(of: [iterated], timeout: 0.5)
        task.cancel()
        await fulfillment(of: [finished], timeout: 0.5)
        monitorTask.cancel()
    }
    
    func testPhotosUpdate_onMonitorSequenceAgain_shouldReceiveUpdates() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let expectedPhotos = [MockNode(handle: 7, name: "7.jpg")]
        let sdk = MockSdk(nodes: expectedPhotos,
                          megaRootNode: MockNode(handle: 1))
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(sdk: sdk,
                          nodeUpdatesProvider: nodeUpdatesProvider)
        
        let monitorTask = Task {
            await sut.monitorPhotoNodeUpdates()
        }
        
        let firstStarted = expectation(description: "first task started")
        let firstSequenceFinished = expectation(description: "first task finished")
        let firstTask = Task {
            firstStarted.fulfill()
            for await _ in await sut.photosUpdatedAsyncSequence {}
            firstSequenceFinished.fulfill()
        }
        await fulfillment(of: [firstStarted], timeout: 0.5)
        firstTask.cancel()
        await fulfillment(of: [firstSequenceFinished], timeout: 0.5)
        
        let started = expectation(description: "first task started")
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let secondTask = Task {
            started.fulfill()
            for await updatedPhotos in await sut.photosUpdatedAsyncSequence {
                XCTAssertEqual(Set(updatedPhotos),
                               Set(expectedPhotos.toNodeEntities()))
                iterated.fulfill()
            }
            finished.fulfill()
        }
        await fulfillment(of: [started], timeout: 0.5)
        continuation.yield(expectedPhotos.toNodeEntities())
        continuation.finish()
        
        await fulfillment(of: [iterated], timeout: 0.5)
        secondTask.cancel()
        await fulfillment(of: [finished], timeout: 0.5)
        monitorTask.cancel()
    }
    
    func testPhotosUpdate_onPhotoMovedToRubbish_shouldRemoveValueFromCache() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let photoInRubbish = MockNode(handle: 76, name: "test.jpg")
        let sdk = MockSdk(nodes: [photoInRubbish], rubbishNodes: [photoInRubbish])
        let photoLocalSource = MockPhotoLocalSource()
        
        let sut = makeSUT(sdk: sdk,
                          nodeUpdatesProvider: nodeUpdatesProvider, photoLocalSource: photoLocalSource)
        
        let monitorTask = Task {
            await sut.monitorPhotoNodeUpdates()
        }
        
        let started = expectation(description: "first task started")
        let iterated = expectation(description: "iterated")
        let task = Task {
            started.fulfill()
            for await updatedPhotos in await sut.photosUpdatedAsyncSequence {
                XCTAssertEqual(Set(updatedPhotos),
                               Set([photoInRubbish.toNodeEntity()]))
                iterated.fulfill()
            }
        }
        await fulfillment(of: [started], timeout: 0.5)
        continuation.yield([photoInRubbish.toNodeEntity()])
        continuation.finish()
        
        await fulfillment(of: [iterated], timeout: 1.0)
        task.cancel()
        
        let cachedPhotos = await photoLocalSource.photos
        XCTAssertTrue(cachedPhotos.isEmpty)
        monitorTask.cancel()
    }
    
    func testPhotosUpdate_onNoneVisualMediaNodeUpdate_shouldNotEmitAnything() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let photoLocalSource = MockPhotoLocalSource()
        
        let sut = makeSUT(nodeUpdatesProvider: nodeUpdatesProvider, photoLocalSource: photoLocalSource)
        
        let monitorTask = Task {
            await sut.monitorPhotoNodeUpdates()
        }
        
        let exp = expectation(description: "should not emit value")
        exp.isInverted = true
        let task = Task {
            for await _ in await sut.photosUpdatedAsyncSequence {
                exp.fulfill()
            }
        }
        
        continuation.yield([NodeEntity(name: "file.txt", handle: 43)])
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        
        let cachedPhotos = await photoLocalSource.photos
        XCTAssertTrue(cachedPhotos.isEmpty)
        monitorTask.cancel()
    }
    
    func testMonitorCacheInvalidationTriggers_onLogoutEvent_shouldClearCaches() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)]
        
        let photoLocalSource = MockPhotoLocalSource(photos: expectedPhotos)
        let notificationCentre = NotificationCenter()
        let sut = makeSUT(
            photoLocalSource: photoLocalSource,
            cacheInvalidationTrigger: CacheInvalidationTrigger(
                notificationCentre: notificationCentre,
                logoutNotificationName: .accountDidLogout,
                didReceiveMemoryWarningNotificationName: { .init("TestMemoryWarningOccurred") }
            ))
        
        let monitorTask = Task {
            await sut.monitorCacheInvalidationTriggers()
        }
        
        let cacheClearExpectation = expectation(description: "Expect cache to be cleared")
        let publisher = await photoLocalSource.$removeAllCachedValuesCalledCount
        let subscription = publisher
            .first(where: { $0 == 1})
            .sink { _ in cacheClearExpectation.fulfill() }
        // Await for monitoring tasks to start
        try await Task.sleep(nanoseconds: 1_000_000_000 / 2)

        notificationCentre.post(name: .accountDidLogout, object: nil)
        
        await fulfillment(of: [cacheClearExpectation], timeout: 1)
        
        subscription.cancel()

        let expectedClearedPhotos = await photoLocalSource.photos
        XCTAssertTrue(expectedClearedPhotos.isEmpty)
        
        let wasForcedCleared = await photoLocalSource.wasForcedCleared
        XCTAssertTrue(wasForcedCleared)
        monitorTask.cancel()
    }
    
    func testMonitorCacheInvalidationTriggers_onMemoryWarning_shouldClearCaches() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)]
        
        let photoLocalSource = MockPhotoLocalSource(photos: expectedPhotos)
        let notificationCentre = NotificationCenter()
        let memoryWarningNotification = Notification.Name("TestMemoryWarningOccurred")
        let sut = makeSUT(
            photoLocalSource: photoLocalSource,
            cacheInvalidationTrigger: CacheInvalidationTrigger(
                notificationCentre: notificationCentre,
                logoutNotificationName: .accountDidLogout,
                didReceiveMemoryWarningNotificationName: { memoryWarningNotification }
            ))
        
        let monitorTask = Task {
            await sut.monitorCacheInvalidationTriggers()
        }
        
        let cacheClearExpectation = expectation(description: "Expect cache to be cleared")
        let publisher = await photoLocalSource.$removeAllCachedValuesCalledCount
        let subscription = publisher
            .first(where: { $0 == 1})
            .sink { _ in cacheClearExpectation.fulfill() }

        // Await for monitoring tasks to start
        try await Task.sleep(nanoseconds: 1_000_000_000 / 2)

        notificationCentre.post(name: memoryWarningNotification, object: nil)
        
        await fulfillment(of: [cacheClearExpectation], timeout: 1)
        subscription.cancel()
        
        let expectedClearedPhotos = await photoLocalSource.photos
        XCTAssertTrue(expectedClearedPhotos.isEmpty)
        
        let wasForcedCleared = await photoLocalSource.wasForcedCleared
        XCTAssertTrue(wasForcedCleared)
        monitorTask.cancel()
    }

    private func makeSUT(
        sdk: MEGASdk = MockSdk(),
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol = MockNodeUpdatesProvider(),
        photoLocalSource: some PhotoLocalSourceProtocol = MockPhotoLocalSource(),
        cacheInvalidationTrigger: CacheInvalidationTrigger = .init(
            notificationCentre: .default,
            logoutNotificationName: .accountDidLogout,
            didReceiveMemoryWarningNotificationName: { Notification.Name("TestMemoryWarningOccurred") })
    ) -> PhotoCacheRepositoryMonitors {
        PhotoCacheRepositoryMonitors(
            sdk: sdk,
            nodeUpdatesProvider: nodeUpdatesProvider,
            photoLocalSource: photoLocalSource,
            cacheInvalidationTrigger: cacheInvalidationTrigger)
    }
}
