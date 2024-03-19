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
    
    func testMonitorUserAlbums_onSetsRetrieved_shouldEmitUserAlbumsFromSetEntities() async throws {
        let albumSets = (1...4).map {
            SetEntity(handle: $0, setType: .album)
        }
        let userAlbumRepository = MockUserAlbumRepository(albums: albumSets)
        let sut = makeSUT(userAlbumRepository: userAlbumRepository)
        
        var albumsSequence = await sut.monitorUserAlbums()
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
        
        var albumsSequence = await sut.monitorUserAlbums()
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
        
        var albumsSequence = await sut.monitorUserAlbums()
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
    
    func testMonitorUseAlbums_onSystemAlbum_shouldYieldNothing() async {
        let sut = makeSUT()
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: AlbumIdEntity.favourite.value, type: .favourite))
            .makeAsyncIterator()
        
        let albumPhotos = await albumPhotosSequence.next()
        
        XCTAssertNil(albumPhotos)
    }
    
    func testMonitorUserAlbumPhotos_userAlbumStartedMonitoring_shouldImmediatelyReturnCorrectAlbumPhotos() async throws {
        let albumId = HandleEntity(65)
        let handles = (1...4).map { HandleEntity($0) }
        let albumElementIds = handles.map { AlbumPhotoIdEntity(albumId: albumId,
                                                               albumPhotoId: $0,
                                                               nodeId: $0)
        }
        let userRepository = MockUserAlbumRepository(albumElementIds: [albumId: albumElementIds])
        let photos = handles.map { NodeEntity(handle: $0) }
        let photosRepository = MockPhotosRepository(photos: photos)
        
        let sut = makeSUT(userAlbumRepository: userRepository,
                          photosRepository: photosRepository)
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user))
            .makeAsyncIterator()
        
        let albumPhotos = await albumPhotosSequence.next()
        
        let expectedPhotos = try handles.map { id in
            AlbumPhotoEntity(photo: try XCTUnwrap(photos.first(where: { $0.handle == id })),
                             albumPhotoId: HandleEntity(id)
            )
        }
        
        XCTAssertEqual(Set(try XCTUnwrap(albumPhotos)),
                       Set(expectedPhotos))
    }
    
    func testMonitorUserAlbumPhotos_userAlbumUpdated_shouldReturnCorrectAlbumPhotos() async throws {
        let albumId = HandleEntity(65)
        let handles = (1...4).map { HandleEntity($0) }
        let albumElementIds = handles.map { AlbumPhotoIdEntity(albumId: albumId,
                                                               albumPhotoId: $0,
                                                               nodeId: $0)
        }
        let (setElementUpdateStream, setElementUpdateContinuation) = AsyncStream
            .makeStream(of: [SetElementEntity].self)
        let userRepository = MockUserAlbumRepository(albumElementIds: [albumId: albumElementIds],
                                                     albumContentUpdated: setElementUpdateStream.eraseToAnyAsyncSequence())
        let photos = handles.map { NodeEntity(handle: $0) }
        let photosRepository = MockPhotosRepository(photos: photos)
        
        let sut = makeSUT(userAlbumRepository: userRepository,
                          photosRepository: photosRepository)
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user))
            .makeAsyncIterator()
        
        let initialPhotos = await albumPhotosSequence.next()
        
        setElementUpdateContinuation.yield([])
        setElementUpdateContinuation.yield([SetElementEntity(handle: 98, ownerId: albumId)])
        setElementUpdateContinuation.finish()
        
        let firstSetUpdateResult = await albumPhotosSequence.next()
        let secondSetUpdateResult = await albumPhotosSequence.next()
        
        let expectedPhotos = try handles.map { id in
            AlbumPhotoEntity(photo: try XCTUnwrap(photos.first(where: { $0.handle == id })),
                             albumPhotoId: HandleEntity(id)
            )
        }
        
        XCTAssertEqual(Set(try XCTUnwrap(initialPhotos)),
                       Set(expectedPhotos))
        XCTAssertEqual(Set(try XCTUnwrap(firstSetUpdateResult)),
                       Set(expectedPhotos))
        XCTAssertNil(secondSetUpdateResult, "Should have only updated for album set element")
    }
    
    func testMonitorUserAlbumPhotos_photosUpdated_shouldYieldIfPhotoIsInAlbum() async throws {
        let albumId = HandleEntity(98)
        let albumElementId = HandleEntity(87)
        let albumPhotoNodeId = HandleEntity(97)
        let albumPhoto = NodeEntity(handle: albumPhotoNodeId)
        let albumPhotoId = AlbumPhotoIdEntity(albumId: albumId,
                                              albumPhotoId: albumElementId,
                                              nodeId: albumPhotoNodeId)
        let expected = AlbumPhotoEntity(photo: albumPhoto, albumPhotoId: albumElementId)
        let userAlbumRepository = MockUserAlbumRepository(albumElementIds: [albumId: [albumPhotoId]])
        let (photosUpdatedStream, photosUpdatedContinuation) = AsyncStream
            .makeStream(of: [NodeEntity].self)
        let photosRepository = MockPhotosRepository(photosUpdated: photosUpdatedStream.eraseToAnyAsyncSequence(),
                                                    photos: [albumPhoto])
        
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          photosRepository: photosRepository)
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user)).makeAsyncIterator()
        
        let initialUserAlbumPhotos = await albumPhotosSequence.next()
        
        photosUpdatedContinuation.yield([NodeEntity(handle: 6)])
        photosUpdatedContinuation.yield([albumPhoto])
        photosUpdatedContinuation.finish()
        
        let updateUserAlbumPhotos = await albumPhotosSequence.next()
        let secondUpdateAlbumPhotos = await albumPhotosSequence.next()
        
        XCTAssertEqual(initialUserAlbumPhotos, [expected])
        XCTAssertEqual(updateUserAlbumPhotos, [expected])
        XCTAssertNil(secondUpdateAlbumPhotos, "Should have only updated once for the album photo")
    }
    
    func testMonitorUserAlbumPhotos_onAllContentRemoved_shouldYieldEmptyAlbumPhotos() async {
        let albumId = HandleEntity(98)
        let (setElementUpdateStream, setElementUpdateContinuation) = AsyncStream
            .makeStream(of: [SetElementEntity].self)
        let userRepository = MockUserAlbumRepository(albumContentUpdated: setElementUpdateStream.eraseToAnyAsyncSequence())
        
        let sut = makeSUT(userAlbumRepository: userRepository)
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user))
            .makeAsyncIterator()
        
        let initialPhotos = await albumPhotosSequence.next()
        
        setElementUpdateContinuation.yield([])
        setElementUpdateContinuation.yield([SetElementEntity(handle: 98, ownerId: albumId, changeTypes: .removed)])
        setElementUpdateContinuation.finish()
        
        let firstSetUpdateResult = await albumPhotosSequence.next()
        
        XCTAssertTrue(initialPhotos?.isEmpty == true)
        XCTAssertTrue(firstSetUpdateResult?.isEmpty == true)
    }
    
    private func makeSUT(
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol = MockMonitorPhotosUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        photosRepository: some PhotosRepositoryProtocol = MockPhotosRepository()
    ) -> MonitorAlbumsUseCase {
        MonitorAlbumsUseCase(monitorPhotosUseCase: monitorPhotosUseCase,
                             mediaUseCase: mediaUseCase,
                             userAlbumRepository: userAlbumRepository,
                             photosRepository: photosRepository)
    }
}
