import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class MonitorSystemAlbumPhotosUseCaseTests: XCTestCase {

    func testMonitorPhotos_userAlbum_shouldReturnInvalidAlbumTypeErrorSequence() async throws {
        let sut = makeSUT()
        
        var iterator = await sut.monitorPhotos(
            for: .user,
            excludeSensitive: false).makeAsyncIterator()
        
        let photosResult = await iterator.next()
        
        XCTAssertThrowsError(try photosResult?.get()) { errorThrown in
            XCTAssertEqual(errorThrown as? AlbumErrorEntity, .invalidType)
        }
    }
    
    func testMonitorPhotos_favouriteAlbum_shouldReturnFavouritePhotosOnly() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Result<[NodeEntity], Error>.self)
        
        for excludeSensitive in [true, false] {
            let monitorPhotosUseCase = MockMonitorPhotosUseCase(
                monitorPhotosAsyncSequence: stream.eraseToAnyAsyncSequence())
            let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase)
            var iterator = await sut.monitorPhotos(
                for: .favourite,
                excludeSensitive: excludeSensitive).makeAsyncIterator()
            
            continuation.yield(.success([]))
            
            let noFavourites = try await iterator.next()?.get()
            XCTAssertEqual(noFavourites, [])
            
            let favouriteNode = NodeEntity(handle: 1, isFavourite: true, isMarkedSensitive: false)
            let sensitiveFavouriteNode = NodeEntity(handle: 1, isFavourite: true, isMarkedSensitive: true)
            let unfavouriteNode = NodeEntity(handle: 2, isFavourite: false, isMarkedSensitive: false)
            let nodes = [favouriteNode, sensitiveFavouriteNode, unfavouriteNode]
            continuation.yield(.success(nodes))
            
            let favourites = try await iterator.next()?.get()
            
            let expectedNodes = if excludeSensitive {
                [favouriteNode]
            } else {
                [favouriteNode, sensitiveFavouriteNode]
            }
            XCTAssertEqual(favourites, expectedNodes, "Invalid favourites for sensitive: \(excludeSensitive)")
            
            let invocations = await monitorPhotosUseCase.invocations
            XCTAssertEqual(invocations, [
                .monitorPhotos(filterOptions: [.allLocations, .allMedia, .favourites],
                               excludeSensitive: excludeSensitive)
            ])
        }
        continuation.finish()
    }
    
    func testMonitorPhotos_rawAndGifAlbum_shouldFilterPhotosCorrectly() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Result<[NodeEntity], Error>.self)
       
        let rawNode = NodeEntity(name: "test.raw", handle: 2, isMarkedSensitive: false)
        let sensitiveRawNode = NodeEntity(name: "test2.raw", handle: 3, isMarkedSensitive: true)
        let gifNode = NodeEntity(name: "test.gif", handle: 4, isMarkedSensitive: false)
        let sensitiveGifNode = NodeEntity(name: "test2.gif", handle: 5, isMarkedSensitive: true)
        let mediaUseCase = MockMediaUseCase(
            rawImageFiles: [rawNode.name, sensitiveRawNode.name],
            gifImageFiles: [gifNode.name, sensitiveGifNode.name])
        
        let testCase = [
            (excludeSensitive: false, type: AlbumEntityType.gif, expected: [gifNode, sensitiveGifNode]),
            (excludeSensitive: true, type: AlbumEntityType.gif, expected: [gifNode]),
            (excludeSensitive: false, type: AlbumEntityType.raw, expected: [rawNode, sensitiveRawNode]),
            (excludeSensitive: true, type: AlbumEntityType.raw, expected: [rawNode])
        ]
        
        let nodes = [
            rawNode,
            sensitiveRawNode,
            gifNode,
            sensitiveGifNode,
            NodeEntity(name: "test2.jpg", handle: 6),
            NodeEntity(name: "test3.png", handle: 7)
        ]
        for (excludeSensitive, type, expectedPhotos) in testCase {
            let monitorPhotosUseCase = MockMonitorPhotosUseCase(
                monitorPhotosAsyncSequence: stream.eraseToAnyAsyncSequence())
            let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                              mediaUseCase: mediaUseCase)
            
            var iterator = await sut.monitorPhotos(
                for: type,
                excludeSensitive: excludeSensitive).makeAsyncIterator()
            
            continuation.yield(.success([.init(name: "test.jpg", handle: 1, isFavourite: true)]))
            
            let firstUpdate = try await iterator.next()?.get()
            XCTAssertEqual(firstUpdate, [], "Expected empty photos for type \(type)")
            
            continuation.yield(.success(nodes))
            
            let secondUpdate = try await iterator.next()?.get()
            XCTAssertEqual(secondUpdate, expectedPhotos, "Invalid filtered photos update for type \(type)")
            let invocations = await monitorPhotosUseCase.invocations
            XCTAssertEqual(invocations, [
                .monitorPhotos(filterOptions: [.allLocations, .allMedia], excludeSensitive: excludeSensitive),
            ])
        }
        
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
