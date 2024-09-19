import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class MonitorUserAlbumPhotosUseCaseTests: XCTestCase {
    
    func testMonitorUserAlbumPhotos_onSystemAlbum_shouldYieldNothing() async {
        let sut = makeSUT()
        
        var albumPhotosSequence = await sut.monitorUserAlbumPhotos(for: AlbumEntity(id: 1, type: .gif),
                                                                   excludeSensitives: false,
                                                                   includeSensitiveInherited: false)
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
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        photosRepository: some PhotosRepositoryProtocol = MockPhotosRepository(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> MonitorUserAlbumPhotosUseCase {
        MonitorUserAlbumPhotosUseCase(
            userAlbumRepository: userAlbumRepository,
            photosRepository: photosRepository,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
}
