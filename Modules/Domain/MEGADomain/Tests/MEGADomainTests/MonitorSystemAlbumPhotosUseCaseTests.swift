import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class MonitorSystemAlbumPhotosUseCaseTests: XCTestCase {

    func testMonitorPhotos_userAlbum_shouldReturnInvalidAlbumTypeErrorSequence() async throws {
        let sut = makeSUT()
        
        var iterator = await sut.monitorPhotos(for: .user).makeAsyncIterator()
        let photosResult = await iterator.next()
        
        XCTAssertThrowsError(try photosResult?.get()) { errorThrown in
            XCTAssertEqual(errorThrown as? AlbumErrorEntity, .invalidType)
        }
    }
    
    func testMonitorPhotos_favouriteAlbum_shouldReturnFavouritePhotosOnly() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Result<[NodeEntity], Error>.self)
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase)
        
        var iterator = await sut.monitorPhotos(for: .favourite).makeAsyncIterator()
        
        continuation.yield(.success([]))
        
        let noFavourites = try await iterator.next()?.get()
        XCTAssertEqual(noFavourites, [])
        
        let favouriteNode = NodeEntity(handle: 1, isFavourite: true)
        let unfavouriteNode = NodeEntity(handle: 2, isFavourite: false)
        continuation.yield(.success([unfavouriteNode, favouriteNode]))
        continuation.finish()
        
        let favourites = try await iterator.next()?.get()
        XCTAssertEqual(favourites, [favouriteNode])
        
        let invocations = await monitorPhotosUseCase.invocations
        XCTAssertEqual(invocations, [.monitorPhotos(filterOptions: [.allLocations, .allMedia, .favourites])])
    }
    
    func testMonitorPhotos_rawAndGifAlbum_shouldFilterPhotosCorrectly() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Result<[NodeEntity], Error>.self)
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: stream.eraseToAnyAsyncSequence())
        let rawNode = NodeEntity(name: "test.raw", handle: 2)
        let gifNode = NodeEntity(name: "test.gif", handle: 3)
        let mediaUseCase = MockMediaUseCase(
            rawImageFiles: [rawNode.name], gifImageFiles: [gifNode.name])
        
        let testCase = [(type: AlbumEntityType.gif, expected: [gifNode]),
                        (type: AlbumEntityType.raw, expected: [rawNode])]
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        
        let nodes = [
            rawNode,
            gifNode,
            NodeEntity(name: "test2.jpg", handle: 4),
            NodeEntity(name: "test3.png", handle: 5)
        ]
        
        for (type, expectedPhotos) in testCase {
            var iterator = await sut.monitorPhotos(for: type).makeAsyncIterator()
            
            continuation.yield(.success([.init(name: "test.jpg", handle: 1, isFavourite: true)]))
            
            let firstUpdate = try await iterator.next()?.get()
            XCTAssertEqual(firstUpdate, [], "Expected empty photos for type \(type)")
            
            continuation.yield(.success(nodes))
            
            let secondUpdate = try await iterator.next()?.get()
            XCTAssertEqual(secondUpdate, expectedPhotos, "Invalid filtered photos update for type \(type)")
        }
        let expectedFilterOption: PhotosFilterOptionsEntity = [.allLocations, .allMedia]
        let invocations = await monitorPhotosUseCase.invocations
        XCTAssertEqual(invocations, [
            .monitorPhotos(filterOptions: expectedFilterOption),
            .monitorPhotos(filterOptions: expectedFilterOption)
        ])
        continuation.finish()
    }

    private func makeSUT(
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol = MockMonitorPhotosUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase()
    ) -> MonitorSystemAlbumPhotosUseCase {
        MonitorSystemAlbumPhotosUseCase(
            monitorPhotosUseCase: monitorPhotosUseCase,
            mediaUseCase: mediaUseCase)
    }
}
