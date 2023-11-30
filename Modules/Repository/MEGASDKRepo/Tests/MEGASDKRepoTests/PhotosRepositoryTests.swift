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
        XCTAssertEqual(photos, expectedPhotos)
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
    
    func testPhotoForHandle_photoSourceContainPhoto_shouldReturnPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle)
        let photoLocalSource = MockPhotoLocalSource(photos: [expectedNode])
        let sut = makeSUT(photoLocalSource: photoLocalSource)
        
        let photo = await sut.photo(forHandle: handle)
        
        XCTAssertEqual(photo, expectedNode)
    }
    
    func testPhotosUpdate_onNodeUpdate_shouldUpdateCacheAndYieldUpdatedPhotos() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let expectedPhotos = [MockNode(handle: 45),
                              MockNode(handle: 65)]
        let sdk = MockSdk(nodes: expectedPhotos,
                          megaRootNode: MockNode(handle: 1))
        let photoLocalSource = MockPhotoLocalSource(photos: [NodeEntity(handle: 4)])
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(sdk: sdk,
                          photoLocalSource: photoLocalSource,
                          nodeUpdatesProvider: nodeUpdatesProvider)
        [[NodeEntity(name: "3.pdf", handle: 54)], [], [NodeEntity(name: "1.jpg", handle: 76)]].forEach {
            continuation.yield($0)
        }
        continuation.finish()
        
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let task = Task {
            for await updatedPhotos in await sut.photosUpdated {
                XCTAssertEqual(Set(updatedPhotos), Set(expectedPhotos.toNodeEntities()))
                let photoSourcePhotos = await photoLocalSource.photos
                XCTAssertEqual(Set(photoSourcePhotos), Set(expectedPhotos.toNodeEntities()))
                iterated.fulfill()
            }
            finished.fulfill()
        }
        await fulfillment(of: [iterated], timeout: 0.5)
        task.cancel()
        await fulfillment(of: [finished], timeout: 0.5)
    }
    
    func testPhotosUpdate_onUpdatePhotoRetrievalEmpty_shouldNotEmitAnything() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let sdk = MockSdk(megaRootNode: MockNode(handle: 1))
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(sdk: sdk,
                          nodeUpdatesProvider: nodeUpdatesProvider)
        
        continuation.yield([NodeEntity(name: "1.jpg", handle: 76)])
        continuation.finish()
        
        let shouldNotIterate = expectation(description: "should not iterate")
        shouldNotIterate.isInverted = true
        let finished = expectation(description: "finished")
        let task = Task {
            for await _ in await sut.photosUpdated {
                shouldNotIterate.fulfill()
            }
            finished.fulfill()
        }
        await fulfillment(of: [shouldNotIterate], timeout: 0.5)
        task.cancel()
        await fulfillment(of: [finished], timeout: 0.5)
    }
    
    func testPhotosUpdate_onMonitorSequenceAgain_shouldReceiveUpdates() async {
        let (stream, continuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let expectedPhotos = [MockNode(handle: 7)]
        let sdk = MockSdk(nodes: expectedPhotos,
                          megaRootNode: MockNode(handle: 1))
        let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(sdk: sdk,
                          nodeUpdatesProvider: nodeUpdatesProvider)
        let firstTask = Task {
            for await _ in await sut.photosUpdated {}
        }
        firstTask.cancel()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let iterated = expectation(description: "iterated")
        let finished = expectation(description: "finished")
        let secondTask = Task {
            for await updatedPhotos in await sut.photosUpdated {
                XCTAssertEqual(Set(updatedPhotos),
                               Set(expectedPhotos.toNodeEntities()))
                iterated.fulfill()
            }
            finished.fulfill()
        }
        continuation.yield([NodeEntity(name: "6.jpg", handle: 76)])
        continuation.finish()
        
        await fulfillment(of: [iterated], timeout: 0.5)
        secondTask.cancel()
        await fulfillment(of: [finished], timeout: 0.5)
    }
    
    private func makeSUT(sdk: MEGASdk = MockSdk(),
                         photoLocalSource: some PhotoLocalSourceProtocol = MockPhotoLocalSource(),
                         nodeUpdatesProvider: some NodeUpdatesProviderProtocol = MockNodeUpdatesProvider(),
                         file: StaticString = #file,
                         line: UInt = #line
    ) -> PhotosRepository {
        let sut = PhotosRepository(sdk: sdk,
                                   photoLocalSource: photoLocalSource,
                                   nodeUpdatesProvider: nodeUpdatesProvider)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
