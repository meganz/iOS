import XCTest
import MEGADomain
import MEGADomainMock

final class AlbumListUseCaseTests: XCTestCase {
    private let photos = [
            NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "2.nef", handle: 2, hasThumbnail: true),
            NodeEntity(name: "3.cr2", handle: 3, hasThumbnail: false),
            NodeEntity(name: "4.dng", handle: 4, hasThumbnail: false),
            NodeEntity(name: "5.gif", handle: 5, hasThumbnail: true)]
    
    private let emptyFavouritesAlbum = AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "", coverNode: nil, count: 0, type: .favourite)
    
    func testLoadCameraUploadNode_whenLoadingFavouriteAlbum_shouldReturnOneRootNode() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository.newRepo,
            mediaUseCase: MockMediaUseCase())
        let rootNode = try await sut.loadCameraUploadNode()
        XCTAssertNotNil(rootNode)
    }
    
    func testLoadAlbums_whenLoadingRawSystemAlbum_shouldReturnFavouriteAndRawAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(photoNodes: photos),
            mediaUseCase: MockMediaUseCase(isRawImage: true))
        let albums = await sut.loadAlbums()
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .raw)
    }
    
    func testLoadAlbums_whenLoadingGifSystemAlbum_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(photoNodes: photos),
            mediaUseCase: MockMediaUseCase(isGifImage: true))
        let albums = await sut.loadAlbums()
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .gif)
    }
    
    func testLoadAlbums_whenLoadingGifSystemAlbumMarkedAsFavourite_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let favouriteGifPhotos = [
            NodeEntity(name: "1.gif", handle: 2, hasThumbnail: true, isFavourite: true),
        ]
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(photoNodes: favouriteGifPhotos),
            mediaUseCase: MockMediaUseCase(isGifImage: true))
        let albums = await sut.loadAlbums()
        XCTAssertTrue(albums.count == 2)
        XCTAssertEqual(albums.first?.type, AlbumEntityType.favourite)
        XCTAssertEqual(albums.last?.type, AlbumEntityType.gif)
    }
    
    func testLoadAlbums_whenLoadingRawSystemAlbumMarkedAsFavourite_shouldReturnFavouriteAndRawAlbumEntity() async throws {
        let favouriteRawPhotos = try (1...4).map {
            NodeEntity(name: "\($0).raw", handle: $0, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:0\($0):04Z".date)
        }
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(photoNodes: favouriteRawPhotos),
            mediaUseCase: MockMediaUseCase(isRawImage: true))
        let albums = await sut.loadAlbums()
        XCTAssertTrue(albums.count == 2)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: favouriteRawPhotos.last, count: UInt(favouriteRawPhotos.count), type: .favourite))
        XCTAssertEqual(albums.last?.type, AlbumEntityType.raw)
    }
    
    func testLoadAlbums_whenLoadingFavouritePhotosAndVideos_shouldFilterThumbnailsAndSelectLatestCover() async throws {
        let expectedCoverNode = NodeEntity(name: "a.mp4", handle: 4, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date)
        let favouritePhotos = [
            NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "1.png", handle: 1, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date)
        ]
        let favouriteVideos = [
            NodeEntity(name: "b.mp4", handle: 3, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date),
            expectedCoverNode
        ]
        let expectedFavouritesCount = UInt((favouritePhotos + favouriteVideos).filter { $0.hasThumbnail && $0.isFavourite }.count)
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(photoNodes: favouritePhotos, videoNodes: favouriteVideos),
            mediaUseCase: MockMediaUseCase())
        let albums = await sut.loadAlbums()
        XCTAssertTrue(albums.count == 1)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: expectedCoverNode, count: expectedFavouritesCount, type: .favourite))
    }
    
    func testCreateUserAlbum_shouldCreateAlbumWithName() async throws {
        let expectedCoverNode = NodeEntity(name: "a.mp4", handle: 4, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date)
        let favouritePhotos = [
            NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "1.png", handle: 1, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date)
        ]
        let favouriteVideos = [
            NodeEntity(name: "b.mp4", handle: 3, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date),
            expectedCoverNode
        ]
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(photoNodes: favouritePhotos, videoNodes: favouriteVideos),
            mediaUseCase: MockMediaUseCase())
        let result = try await sut.createUserAlbum(with: "Custom Album")
        XCTAssertEqual(result.name, "Custom Album")
    }
}
