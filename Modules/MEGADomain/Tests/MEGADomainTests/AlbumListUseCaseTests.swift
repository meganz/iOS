import XCTest
import MEGADomain
import MEGADomainMock

final class AlbumListUseCaseTests: XCTestCase {
    let photos = [
            NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "2.nef", handle: 2, hasThumbnail: true),
            NodeEntity(name: "3.cr2", handle: 3, hasThumbnail: false),
            NodeEntity(name: "4.dng", handle: 4, hasThumbnail: false),
            NodeEntity(name: "5.gif", handle: 5, hasThumbnail: true)]
    
    func testLoadCameraUploadNode_whenLoadingFavouriteAlbum_shouldReturnOneRootNode() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository.newRepo,
            mediaUseCase: MockMediaUseCase())
        let rootNode = try await sut.loadCameraUploadNode()
        XCTAssertNotNil(rootNode)
    }
    
    func testLoadAlbums_whenLoadingRawSystemAlbum_shouldReturnRawAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(nodes: photos),
            mediaUseCase: MockMediaUseCase(isRawImage: true))
        let albums = try await sut.loadAlbums()
        XCTAssert(albums.count == 1)
    }
    
    func testLoadAlbums_whenLoadingGifSystemAlbum_shouldReturnGifAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            fileSearchRepository: MockFileSearchRepository(nodes: photos),
            mediaUseCase: MockMediaUseCase(isGifImage: true))
        let albums = try await sut.loadAlbums()
        XCTAssert(albums.count == 1)
    }

}
