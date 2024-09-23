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
        let photosSequence = SingleItemAsyncSequence<Result<[NodeEntity], Error>>(item: .success(photos))
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase)
        
        var albumsSequence = await sut.monitorSystemAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let albums = try await albumsSequence.next()?.get()
        
        let expected = [AlbumEntity(id: AlbumIdEntity.favourite.value,
                                    coverNode: photos.last, count: photos.count, type: .favourite)]
        XCTAssertEqual(albums, expected)
    }
    
    func testMonitorSystemAlbums_photosContainsGifOnly_shouldReturnFavouriteWithGifAlbum() async throws {
        let photos = try (1...4).map {
            NodeEntity(name: "\($0).gif", handle: $0, hasThumbnail: true,
                       modificationTime: try "2024-03-10T22:0\($0):04Z".date, mediaType: .image)
        }
        let photosSequence = SingleItemAsyncSequence<Result<[NodeEntity], Error>>(item: .success(photos))
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(gifImageFiles: photos.map(\.name))
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        
        var albumsSequence = await sut.monitorSystemAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let albums = try await albumsSequence.next()?.get()
        
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
        
        let photosSequence = SingleItemAsyncSequence<Result<[NodeEntity], Error>>(item: .success(photos))
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(rawImageFiles: photos.map(\.name))
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        
        var albumsSequence = await sut.monitorSystemAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let albums = try await albumsSequence.next()?.get()
        
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
        
        let photosSequence = SingleItemAsyncSequence<Result<[NodeEntity], Error>>(item: .success(photos))
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(rawImageFiles: [rawCover.name],
                                            gifImageFiles: [gifCover.name])
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        var albumsSequence = await sut.monitorSystemAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let albums = try await albumsSequence.next()?.get()
        
        let expected = [AlbumEntity(id: AlbumIdEntity.favourite.value, coverNode: favouriteCover,
                                    count: 1, type: .favourite),
                        AlbumEntity(id: AlbumIdEntity.gif.value, coverNode: gifCover,
                                    count: 1, type: .gif),
                        AlbumEntity(id: AlbumIdEntity.raw.value, coverNode: rawCover,
                                    count: 1, type: .raw)]
        XCTAssertEqual(albums, expected)
    }
    
    func testMonitorSystemAlbums_failedToRetriveAllPhotos_shouldReturnFailedResultType() async {
        let photosSequence = SingleItemAsyncSequence<Result<[NodeEntity], Error>>(item: .failure(GenericErrorEntity()))
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase)
        var albumsSequence = await sut.monitorSystemAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let albumsResult = await albumsSequence.next()
        
        switch albumsResult {
        case .failure(let error):
            XCTAssertTrue(error is GenericErrorEntity)
        default: XCTFail("Expected Failure")
        }
    }
    
    func testMonitorSystemAlbumsExcludeSensitive_onSensitivePhotos_shouldNotUseSensitivesInAlbums() async throws {
        let favouriteCover = NodeEntity(name: "file.jpg", handle: 1, hasThumbnail: true, isFavourite: true,
                                        modificationTime: try "2024-03-11T20:01:04Z".date)
        let favouriteSensitive = NodeEntity(name: "file.jpg", handle: 4, hasThumbnail: true, isFavourite: true,
                                            isMarkedSensitive: true, modificationTime: try "2024-05-01T20:01:04Z".date)
        let gifCover = NodeEntity(name: "gif.gif", handle: 5, hasThumbnail: true,
                                  modificationTime: try "2024-03-10T22:05:04Z".date)
        let rawCover = NodeEntity(name: "raw.raw", handle: 2, hasThumbnail: true,
                                  modificationTime: try "2024-03-11T20:01:04Z".date)
        let rawSensitive = NodeEntity(name: "raw.raw", handle: 9, hasThumbnail: true,
                                      isMarkedSensitive: true, modificationTime: try "2024-03-11T20:01:04Z".date)
        let photos = [
            favouriteCover,
            favouriteSensitive,
            rawCover,
            rawSensitive,
            gifCover
        ]
        
        let photosSequence = SingleItemAsyncSequence<Result<[NodeEntity], Error>>(item: .success(photos))
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(rawImageFiles: [rawCover.name, rawSensitive.name],
                                            gifImageFiles: [gifCover.name])
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase)
        
        var albumsSequence = await sut.monitorSystemAlbums(excludeSensitives: true)
            .makeAsyncIterator()
        
        let albums = try await albumsSequence.next()?.get()
        
        let expected = [AlbumEntity(id: AlbumIdEntity.favourite.value, coverNode: favouriteCover,
                                    count: 1, type: .favourite),
                        AlbumEntity(id: AlbumIdEntity.gif.value, coverNode: gifCover,
                                    count: 1, type: .gif),
                        AlbumEntity(id: AlbumIdEntity.raw.value, coverNode: rawCover,
                                    count: 1, type: .raw)]
        XCTAssertEqual(albums, expected)
    }
    
    func testMonitorUserAlbums_onSetsRetrieved_shouldEmitUserAlbumsFromSetEntities() async throws {
        let albumSets = (1...4).map {
            SetEntity(handle: $0, setType: .album)
        }
        let userAlbumRepository = MockUserAlbumRepository(albums: albumSets)
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        var albumsSequence = await sut.monitorUserAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let albums = await albumsSequence.next()
        
        let expectedAlbums = albumSets.map {
            AlbumEntity(id: $0.handle,
                        name: $0.name,
                        coverNode: nil,
                        count: 0,
                        type: .user,
                        creationTime: $0.creationTime,
                        modificationTime: $0.modificationTime,
                        sharedLinkStatus: .exported($0.isExported))
        }
        
        XCTAssertEqual(Set(try XCTUnwrap(albums)), Set(expectedAlbums))
    }
    
    func testMonitorUserAlbums_onAlbumSetsUpdated_shouldEmitInitalUserAlbumsThenUpdatedSets() async throws {
        let albumSets = (1...4).map {
            SetEntity(handle: $0, setType: .album)
        }
        let setsSequence = SingleItemAsyncSequence<[SetEntity]>(item: albumSets)
            .eraseToAnyAsyncSequence()
        let userAlbumRepository = MockUserAlbumRepository(albums: albumSets,
                                                          albumsUpdated: setsSequence)
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        var albumsSequence = await sut.monitorUserAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let initial = await albumsSequence.next()
        let updated = await albumsSequence.next()
        
        let expectedAlbums = albumSets.map {
            AlbumEntity(id: $0.handle,
                        name: $0.name,
                        coverNode: nil,
                        count: 0,
                        type: .user,
                        creationTime: $0.creationTime,
                        modificationTime: $0.modificationTime,
                        sharedLinkStatus: .exported($0.isExported))
        }
        
        XCTAssertEqual(Set(try XCTUnwrap(initial)), Set(expectedAlbums))
        XCTAssertEqual(Set(try XCTUnwrap(updated)), Set(expectedAlbums))
    }
    
    func testMonitorUserAlbums_albumSetWithCover_shouldRetrieveCoverFromPhotos() async throws {
        let coverId = HandleEntity(65)
        let albumSet = SetEntity(handle: 1, coverId: coverId, setType: .album)
        let expectedCover = NodeEntity(name: "cover.jpg", handle: 4)
        let albumId = AlbumPhotoIdEntity(albumId: albumSet.handle,
                                         albumPhotoId: coverId,
                                         nodeId: expectedCover.handle)
        
        let userAlbumRepository = MockUserAlbumRepository(albums: [albumSet],
                                                          albumElementIds: [albumSet.handle: [albumId]])
        let photosRepository = MockPhotosRepository(photos: [expectedCover])
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          photosRepository: photosRepository)
        
        var albumsSequence = await sut.monitorUserAlbums(excludeSensitives: false)
            .makeAsyncIterator()
        
        let albums = await albumsSequence.next()
        
        let expectedAlbum = AlbumEntity(id: albumSet.handle,
                                        name: albumSet.name,
                                        coverNode: expectedCover,
                                        count: 0,
                                        type: .user,
                                        creationTime: albumSet.creationTime,
                                        modificationTime: albumSet.modificationTime,
                                        sharedLinkStatus: .exported(albumSet.isExported))
        
        XCTAssertEqual(Set(try XCTUnwrap(albums)), Set([expectedAlbum]))
    }
    
    func testMonitorUserAlbumsExcludeSensitives_coverMarkedHidden_shouldNotAlbumsWithHiddenCovers() async {
        let setCoverElementId = HandleEntity(6)
        let setCoverMarkedSensitiveElementId = HandleEntity(7)
        let setCover = SetEntity(handle: 1, coverId: setCoverElementId, setType: .album)
        let setCoverMarkedSensitive = SetEntity(handle: 2, coverId: setCoverMarkedSensitiveElementId, setType: .album)
        let albumSets = [
            setCover,
            setCoverMarkedSensitive
        ]
        let cover = NodeEntity(name: "file.jpg", handle: 1, hasThumbnail: true, isMarkedSensitive: false)
        let coverSensitive = NodeEntity(name: "file 2.jpg", handle: 2, hasThumbnail: true,
                                        isMarkedSensitive: true)
        
        let albumElementIds: [HandleEntity: [AlbumPhotoIdEntity]] = [
            setCover.handle: [AlbumPhotoIdEntity(
                albumId: setCover.handle, albumPhotoId: setCoverElementId, nodeId: cover.handle)],
            setCoverMarkedSensitive.handle: [AlbumPhotoIdEntity(
                albumId: setCoverMarkedSensitive.handle, albumPhotoId: setCoverMarkedSensitiveElementId, nodeId: coverSensitive.handle)]
        ]
        let userAlbumRepository = MockUserAlbumRepository(albums: albumSets,
                                                          albumElementIds: albumElementIds)
        let photosRepository = MockPhotosRepository(photos: [cover, coverSensitive])
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          photosRepository: photosRepository)
        
        var albumsSequence = await sut.monitorUserAlbums(excludeSensitives: true)
            .makeAsyncIterator()
        
        let albums = await albumsSequence.next()
        
        let expectedAlbums = albumSets.map {
            AlbumEntity(id: $0.handle,
                        name: $0.name,
                        coverNode: $0.handle == setCover.handle ? cover : nil,
                        count: 0,
                        type: .user,
                        creationTime: $0.creationTime,
                        modificationTime: $0.modificationTime,
                        sharedLinkStatus: .exported($0.isExported))
        }
        
        XCTAssertEqual(Set(try XCTUnwrap(albums)), Set(expectedAlbums))
    }
    
    private func makeSUT(
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol = MockMonitorPhotosUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        photosRepository: some PhotosRepositoryProtocol = MockPhotosRepository(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> MonitorAlbumsUseCase {
        MonitorAlbumsUseCase(monitorPhotosUseCase: monitorPhotosUseCase,
                             mediaUseCase: mediaUseCase,
                             userAlbumRepository: userAlbumRepository,
                             photosRepository: photosRepository,
                             sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
}
