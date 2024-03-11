import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class MonitorAlbumsUseCaseTests: XCTestCase {
    
    func testMonitorSystemAlbums_photosContainsFavouriteOnly_shouldReturnFavouriteWithLatestAsCover() async throws {
        let photos = try (1...4).map {
            NodeEntity(name: "\($0).jpg", handle: $0, hasThumbnail: true, isFavourite: true,
                       modificationTime: try "2024-03-10T22:0\($0):04Z".date, mediaType: .image)
        }
        let photosSequence = SingleItemAsyncSequence<[NodeEntity]>(item: photos)
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase)
        
        var albumsSequence = try await sut.monitorSystemAlbums()
            .makeAsyncIterator()
        
        let albums = await albumsSequence.next()
        
        let expected = [AlbumEntity(id: AlbumIdEntity.favourite.value,
                                    coverNode: photos.last, count: photos.count, type: .favourite)]
        XCTAssertEqual(albums, expected)
    }
    
    func testMonitorSystemAlbums_photosContainsGifOnly_shouldReturnFavouriteWithGifAlbum() async throws {
        let photos = try (1...4).map {
            NodeEntity(name: "\($0).gif", handle: $0, hasThumbnail: true,
                       modificationTime: try "2024-03-10T22:0\($0):04Z".date, mediaType: .image)
        }
        let photosSequence = SingleItemAsyncSequence<[NodeEntity]>(item: photos)
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(gifImageFiles: photos.map(\.name))
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        
        var albumsSequence = try await sut.monitorSystemAlbums()
            .makeAsyncIterator()
        
        let albums = await albumsSequence.next()
        
        let expected = [AlbumEntity(id: AlbumIdEntity.favourite.value, coverNode: nil,
                                    count: 0, type: .favourite),
                        AlbumEntity(id: AlbumIdEntity.gif.value,
                                    coverNode: photos.last, count: photos.count, type: .gif)]
        XCTAssertEqual(albums, expected)
    }
    
    func testMonitorSystemAlbums_photosContainsRawPhotosOnly_shouldReturnFavouriteAlbumAndRawAlbum() async throws {
        let rawCover = NodeEntity(name: "2.raw", handle: 2, hasThumbnail: true,
                                  modificationTime: try "2024-03-11T20:01:04Z".date)
        let photos = [
            NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true,
                       modificationTime: try "2024-03-11T20:01:04Z".date),
            rawCover,
            NodeEntity(name: "3.raw", handle: 3, hasThumbnail: true,
                       modificationTime: try "2024-03-09T20:01:04Z".date),
            NodeEntity(name: "4.raw", handle: 4, hasThumbnail: true,
                       modificationTime: try "2024-02-01T20:01:04Z".date)
        ]
        
        let photosSequence = SingleItemAsyncSequence<[NodeEntity]>(item: photos)
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(rawImageFiles: photos.map(\.name))
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        
        var albumsSequence = try await sut.monitorSystemAlbums()
            .makeAsyncIterator()
        
        let albums = await albumsSequence.next()
        
        let expected = [AlbumEntity(id: AlbumIdEntity.favourite.value, coverNode: nil, count: 0, type: .favourite),
                        AlbumEntity(id: AlbumIdEntity.raw.value, coverNode: rawCover, count: photos.count, type: .raw)]
        XCTAssertEqual(albums, expected)
    }
    
    func testMonitorSystemAlbums_photosContainsFavouriteGifRawPhotos_shouldReturnCorrectAlbums() async throws {
        let favouriteCover = NodeEntity(name: "file.jpg", handle: 1, hasThumbnail: true, isFavourite: true,
                                         modificationTime: try "2024-03-11T20:01:04Z".date)
        let gifCover = NodeEntity(name: "gif.gif", handle: 5, hasThumbnail: true,
                             modificationTime: try "2024-03-10T22:05:04Z".date)
        let rawCover = NodeEntity(name: "raw.raw", handle: 2, hasThumbnail: true,
                                  modificationTime: try "2024-03-11T20:01:04Z".date)
        let photos = [
            favouriteCover,
            rawCover,
            gifCover
        ]
        
        let photosSequence = SingleItemAsyncSequence<[NodeEntity]>(item: photos)
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(rawImageFiles: [rawCover.name],
                                            gifImageFiles: [gifCover.name])
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        var albumsSequence = try await sut.monitorSystemAlbums()
            .makeAsyncIterator()
        
        let albums = await albumsSequence.next()
        
        let expected = [AlbumEntity(id: AlbumIdEntity.favourite.value, coverNode: favouriteCover,
                                    count: 1, type: .favourite),
                        AlbumEntity(id: AlbumIdEntity.gif.value, coverNode: gifCover,
                                    count: 1, type: .gif),
                        AlbumEntity(id: AlbumIdEntity.raw.value, coverNode: rawCover,
                                    count: 1, type: .raw)]
        XCTAssertEqual(albums, expected)
    }
    
    private func makeSUT(
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol = MockMonitorPhotosUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase()
    ) -> MonitorAlbumsUseCase {
        MonitorAlbumsUseCase(monitorPhotosUseCase: monitorPhotosUseCase,
                             mediaUseCase: mediaUseCase)
    }
}
