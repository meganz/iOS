import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class PhotosRepositoryTests: XCTestCase {
    func testAllPhotos_rootNodeNotFound_shouldThrowError() async {
        let sut = makeSUT()
        do {
            _ = try await sut.allPhotos()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? NodeErrorEntity, NodeErrorEntity.nodeNotFound)
        }
    }
    
    func testAllPhotos_photoSourceEmpty_shouldRetrievePhotosThroughSearch() async throws {
        let expectedPhotos = [MockNode(handle: 45),
                              MockNode(handle: 65)]
        let sdk = MockSdk(nodes: expectedPhotos,
                          megaRootNode: MockNode(handle: 1))
        let sut = makeSUT(sdk: sdk)
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(Set(photos), Set(expectedPhotos.toNodeEntities()))
    }
    
    func testAllPhotos_multipleCallsAndSourceEmpty_shouldEnsureThatSearchOnlyCalledOnceForImageAndOnceForVideos() async throws {
        
        let sdk = MockSdk(megaRootNode: MockNode(handle: 1))
        let sut = makeSUT(sdk: sdk)
        
        async let photosOne = try await sut.allPhotos()
        async let photosTwo = try await sut.allPhotos()
        
        _ = try await photosOne + photosTwo
        
        XCTAssertEqual(sdk.nodeListSearchCallCount, 2)
    }
    
    func testAllPhotos_photoSourceContainsPhotos_shouldRetrievePhotos() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)
        ]
        let photoLocalSource = MockPhotoLocalSource(photos: expectedPhotos)
        let sut = makeSUT(photoLocalSource: photoLocalSource)
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(Set(photos), Set(expectedPhotos))
    }
    
    func testPhotoForHandle_photoSourceDontContainPhoto_shouldRetrieveAndSetPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = MockNode(handle: handle)
        let sdk = MockSdk(nodes: [expectedNode])
        let photoLocalSource = MockPhotoLocalSource()
        let sut = makeSUT(sdk: sdk,
                          photoLocalSource: photoLocalSource)
        
        let photo = await sut.photo(forHandle: handle)
        
        XCTAssertEqual(photo, expectedNode.toNodeEntity())
        let photoSourcePhotos = await photoLocalSource.photos
        XCTAssertEqual(photoSourcePhotos, [expectedNode.toNodeEntity()])
    }
    
    func testPhotoForHandle_SDKCantGetNode_shouldReturnNil() async {
        let sut = makeSUT()
        
        let photo = await sut.photo(forHandle: 6)
        
        XCTAssertNil(photo)
    }
    
    func testPhotoForHandle_nodeInRubbish_shouldReturnNil() async {
        let sdk = MockSdk(rubbishNodes: [MockNode(handle: 6)])
        let sut = makeSUT(sdk: sdk)
        
        let photo = await sut.photo(forHandle: 6)
        
        XCTAssertNil(photo)
    }
    
    func testPhotoForHandle_photoSourceContainPhoto_shouldReturnPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle)
        let photoLocalSource = MockPhotoLocalSource(photos: [expectedNode,
                                                             NodeEntity(handle: 7)])
        let sut = makeSUT(photoLocalSource: photoLocalSource)
        
        let photo = await sut.photo(forHandle: handle)
        
        XCTAssertEqual(photo, expectedNode)
    }
    
    func testPhotosUpdate_onNodeUpdate_shouldUpdateCacheAndYieldUpdatedPhotos() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let fileNode = MockNode(handle: 54, name: "3.pdf")
        let photoNode = MockNode(handle: 76, name: "1.jpg")
        let cachedPhoto = NodeEntity(handle: 4)
        let sdk = MockSdk(nodes: [fileNode, photoNode],
                          megaRootNode: MockNode(handle: 1))
        let photoLocalSource = MockPhotoLocalSource(photos: [cachedPhoto])
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(sdk: sdk,
                          photoLocalSource: photoLocalSource,
                          nodeUpdatesProvider: nodeUpdatesProvider)
        
        let started = expectation(description: "started")
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let nodeUpdates = [[fileNode.toNodeEntity()], [], [photoNode.toNodeEntity()]]
        let task = Task {
            started.fulfill()
            for await updatedPhotos in await sut.photosUpdated() {
                XCTAssertEqual(Set(updatedPhotos), Set([photoNode.toNodeEntity()]))
                let photoSourcePhotos = await photoLocalSource.photos
                XCTAssertEqual(Set(photoSourcePhotos), Set([photoNode.toNodeEntity(), cachedPhoto]))
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
        
        let firstStarted = expectation(description: "first task started")
        let firstSequenceFinished = expectation(description: "first task finished")
        let firstTask = Task {
            firstStarted.fulfill()
            for await _ in await sut.photosUpdated() {}
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
            for await updatedPhotos in await sut.photosUpdated() {
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
    }
    
    func testPhotosUpdate_onPhotoMovedToRubbish_shouldRemoveValueFromCache() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let photoInRubbish = MockNode(handle: 76, name: "test.jpg")
        let sdk = MockSdk(nodes: [photoInRubbish], rubbishNodes: [photoInRubbish])
        let photoLocalSource = MockPhotoLocalSource()
        
        let sut = makeSUT(sdk: sdk,
                          photoLocalSource: photoLocalSource,
                          nodeUpdatesProvider: nodeUpdatesProvider)
        
        let started = expectation(description: "first task started")
        let iterated = expectation(description: "iterated")
        let task = Task {
            started.fulfill()
            for await updatedPhotos in await sut.photosUpdated() {
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
    }
    
    func testPhotosUpdate_onNoneVisualMediaNodeUpdate_shouldNotEmitAnything() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let photoLocalSource = MockPhotoLocalSource()
        
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          nodeUpdatesProvider: nodeUpdatesProvider)
        
        let exp = expectation(description: "should not emit value")
        exp.isInverted = true
        let task = Task {
            for await _ in await sut.photosUpdated() {
                exp.fulfill()
            }
        }
        
        continuation.yield([NodeEntity(name: "file.txt", handle: 43)])
        continuation.finish()
        
        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
        
        let cachedPhotos = await photoLocalSource.photos
        XCTAssertTrue(cachedPhotos.isEmpty)
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
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(Set(photos), Set(expectedPhotos))
        
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
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(Set(photos), Set(expectedPhotos))
        
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
    }

    private func makeSUT(sdk: MEGASdk = MockSdk(),
                         photoLocalSource: some PhotoLocalSourceProtocol = MockPhotoLocalSource(),
                         nodeUpdatesProvider: some NodeUpdatesProviderProtocol = MockNodeUpdatesProvider(),
                         cacheInvalidationTrigger: CacheInvalidationTrigger = .init(
                            notificationCentre: .default,
                            logoutNotificationName: .accountDidLogout,
                            didReceiveMemoryWarningNotificationName: { Notification.Name("TestMemoryWarningOccurred") }),
                         file: StaticString = #file,
                         line: UInt = #line
    ) -> PhotosRepository {
        let sut = PhotosRepository(sdk: sdk,
                                   photoLocalSource: photoLocalSource,
                                   nodeUpdatesProvider: nodeUpdatesProvider, 
                                   cacheInvalidationTrigger: cacheInvalidationTrigger)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
