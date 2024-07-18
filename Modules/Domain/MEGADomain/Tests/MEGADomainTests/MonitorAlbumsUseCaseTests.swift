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
        let gifInheritedSensitive = NodeEntity(name: "gif.gif", handle: 57, hasThumbnail: true,
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
            gifCover,
            gifInheritedSensitive
        ]
        let inheritedSensitivityResults: [HandleEntity: Result<Bool, Error>] = [
            favouriteCover.handle: .success(false),
            gifCover.handle: .success(false),
            gifInheritedSensitive.handle: .success(true),
            rawCover.handle: .success(false)
        ]
        
        let photosSequence = SingleItemAsyncSequence<Result<[NodeEntity], Error>>(item: .success(photos))
            .eraseToAnyAsyncSequence()
        let monitorPhotosUseCase = MockMonitorPhotosUseCase(
            monitorPhotosAsyncSequence: photosSequence)
        let mediaUseCase = MockMediaUseCase(rawImageFiles: [rawCover.name, rawSensitive.name],
                                            gifImageFiles: [gifCover.name, gifInheritedSensitive.name])
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isInheritingSensitivityResults: inheritedSensitivityResults)
        let sut = makeSUT(monitorPhotosUseCase: monitorPhotosUseCase,
                          mediaUseCase: mediaUseCase,
                          sensitiveNodeUseCase: sensitiveNodeUseCase)
        
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
    
    func testMonitorUserAlbums_onSystemAlbum_shouldYieldNothing() async {
        let sut = makeSUT()
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: AlbumIdEntity.favourite.value, type: .favourite),
                                                                   excludeSensitives: false, includeSensitiveInherited: false)
            .makeAsyncIterator()
        
        let albumPhotos = await albumPhotosSequence.next()
        
        XCTAssertNil(albumPhotos)
    }
    
    func testMonitorUserAlbumsExcludeSensitives_coverMarkedHidden_shouldNotAlbumsWithHiddenCovers() async {
        let setCoverElementId = HandleEntity(6)
        let setCoverMarkedSensitiveElementId = HandleEntity(7)
        let setCoverInheritedSensitiveElementId = HandleEntity(8)
        let setCover = SetEntity(handle: 1, coverId: setCoverElementId, setType: .album)
        let setCoverMarkedSensitive = SetEntity(handle: 2, coverId: setCoverMarkedSensitiveElementId, setType: .album)
        let setCoverInheritedSensitive = SetEntity(handle: 3, coverId: setCoverInheritedSensitiveElementId, setType: .album)
        let albumSets = [
            setCover,
            setCoverMarkedSensitive,
            setCoverInheritedSensitive
        ]
        let cover = NodeEntity(name: "file.jpg", handle: 1, hasThumbnail: true, isMarkedSensitive: false)
        let coverSensitive = NodeEntity(name: "file 2.jpg", handle: 2, hasThumbnail: true,
                                        isMarkedSensitive: true)
        let coverInheritedSensitive = NodeEntity(name: "gif.gif", handle: 3, hasThumbnail: true)
        
        let albumElementIds: [HandleEntity: [AlbumPhotoIdEntity]] = [
            setCover.handle: [AlbumPhotoIdEntity(
                albumId: setCover.handle, albumPhotoId: setCoverElementId, nodeId: cover.handle)],
            setCoverMarkedSensitive.handle: [AlbumPhotoIdEntity(
                albumId: setCoverMarkedSensitive.handle, albumPhotoId: setCoverMarkedSensitiveElementId, nodeId: coverSensitive.handle)],
            setCoverInheritedSensitive.handle: [AlbumPhotoIdEntity(
                albumId: setCoverInheritedSensitive.handle, albumPhotoId: setCoverInheritedSensitiveElementId, nodeId: coverInheritedSensitive.handle)]
        ]
        let inheritedSensitivityResults: [HandleEntity: Result<Bool, Error>] = [
            cover.handle: .success(false),
            coverInheritedSensitive.handle: .success(true)
        ]
        let userAlbumRepository = MockUserAlbumRepository(albums: albumSets,
                                                          albumElementIds: albumElementIds)
        let photosRepository = MockPhotosRepository(photos: [cover, coverSensitive, coverInheritedSensitive])
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isInheritingSensitivityResults: inheritedSensitivityResults)
        let sut = makeSUT(userAlbumRepository: userAlbumRepository,
                          photosRepository: photosRepository,
                          sensitiveNodeUseCase: sensitiveNodeUseCase)
        
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
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user),
                                                                   excludeSensitives: false,
                                                                   includeSensitiveInherited: false)
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
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user),
                                                                   excludeSensitives: false, includeSensitiveInherited: false)
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
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user),
                                                                   excludeSensitives: false, includeSensitiveInherited: false)
            .makeAsyncIterator()
        
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
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user),
                                                                   excludeSensitives: false, includeSensitiveInherited: false)
            .makeAsyncIterator()
        
        let initialPhotos = await albumPhotosSequence.next()
        
        setElementUpdateContinuation.yield([])
        setElementUpdateContinuation.yield([SetElementEntity(handle: 98, ownerId: albumId, changeTypes: .removed)])
        setElementUpdateContinuation.finish()
        
        let firstSetUpdateResult = await albumPhotosSequence.next()
        
        XCTAssertTrue(initialPhotos?.isEmpty == true)
        XCTAssertTrue(firstSetUpdateResult?.isEmpty == true)
    }
    
    func testMonitorUserAlbumPhotosExcludeSensitivesWithIncludeSensitiveInherited_containsSensitivePhotos_shouldNotYieldSensitivePhotos() async throws {
        for includeSensitiveInherited in [true, false] {
            let albumId = HandleEntity(5)
            let albumNormalElementId = HandleEntity(98)
            let albumSensitiveElementId = HandleEntity(543)
            let albumInheritedElementId = HandleEntity(54)
            let normal = NodeEntity(name: "file.jpg", handle: 1, hasThumbnail: true, isMarkedSensitive: false)
            let sensitive = NodeEntity(name: "file 2.jpg", handle: 2, hasThumbnail: true,
                                       isMarkedSensitive: true)
            let inheritedSensitive = NodeEntity(name: "gif.gif", handle: 3, hasThumbnail: true, isMarkedSensitive: false)
            let albumElementIds = [
                AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: albumNormalElementId, nodeId: normal.handle),
                AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: albumSensitiveElementId, nodeId: sensitive.handle),
                AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: albumInheritedElementId, nodeId: inheritedSensitive.handle)
            ]
            let inheritedSensitivityResults: [HandleEntity: Result<Bool, Error>] = [
                normal.handle: .success(false),
                inheritedSensitive.handle: .success(true)
            ]
            
            let userRepository = MockUserAlbumRepository(albumElementIds: [albumId: albumElementIds])
            let photos = [normal, sensitive, inheritedSensitive]
            let photosRepository = MockPhotosRepository(photos: photos)
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isInheritingSensitivityResults: inheritedSensitivityResults)
            let sut = makeSUT(userAlbumRepository: userRepository,
                              photosRepository: photosRepository,
                              sensitiveNodeUseCase: sensitiveNodeUseCase)
            
            var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user),
                                                                       excludeSensitives: true,
                                                                       includeSensitiveInherited: includeSensitiveInherited)
                .makeAsyncIterator()
            
            let albumPhotos = await albumPhotosSequence.next()
            
            let expected = [AlbumPhotoEntity(photo: normal,
                                             albumPhotoId: albumNormalElementId,
                                             isSensitiveInherited: includeSensitiveInherited ? false : nil)
            ]
            
            XCTAssertEqual(try XCTUnwrap(albumPhotos), expected)
        }
    }
    
    func testMonitorUserAlbumPhotosExcludeSensitivesIncludeInherited_containsSensitivePhotos_shouldYieldSesitivePhotosWithInherited() async throws {
        let albumId = HandleEntity(5)
        let albumNormalElementId = HandleEntity(98)
        let albumSensitiveElementId = HandleEntity(543)
        let albumInheritedElementId = HandleEntity(54)
        let normal = NodeEntity(name: "file.jpg", handle: 1, hasThumbnail: true, isMarkedSensitive: false)
        let sensitive = NodeEntity(name: "file 2.jpg", handle: 2, hasThumbnail: true,
                                   isMarkedSensitive: true)
        let inheritedSensitive = NodeEntity(name: "gif.gif", handle: 3, hasThumbnail: true, isMarkedSensitive: false)
        let albumElementIds = [
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: albumNormalElementId, nodeId: normal.handle),
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: albumSensitiveElementId, nodeId: sensitive.handle),
            AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: albumInheritedElementId, nodeId: inheritedSensitive.handle)
        ]
        let inheritedSensitivityResults: [HandleEntity: Result<Bool, Error>] = [
            normal.handle: .success(false),
            sensitive.handle: .success(true),
            inheritedSensitive.handle: .success(true)
        ]
        
        let userRepository = MockUserAlbumRepository(albumElementIds: [albumId: albumElementIds])
        let photos = [normal, sensitive, inheritedSensitive]
        let photosRepository = MockPhotosRepository(photos: photos)
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isInheritingSensitivityResults: inheritedSensitivityResults)
        let sut = makeSUT(userAlbumRepository: userRepository,
                          photosRepository: photosRepository,
                          sensitiveNodeUseCase: sensitiveNodeUseCase)
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: albumId, type: .user),
                                                                   excludeSensitives: false,
                                                                   includeSensitiveInherited: true)
            .makeAsyncIterator()
        
        let albumPhotos = await albumPhotosSequence.next()
        let expected = Set([AlbumPhotoEntity(photo: normal, albumPhotoId: albumNormalElementId, isSensitiveInherited: false),
                            AlbumPhotoEntity(photo: sensitive, albumPhotoId: albumSensitiveElementId, isSensitiveInherited: true),
                            AlbumPhotoEntity(photo: inheritedSensitive, albumPhotoId: albumInheritedElementId, isSensitiveInherited: true)])
        XCTAssertEqual(Set(try XCTUnwrap(albumPhotos)), expected)
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
