import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumCoverUseCaseTests: XCTestCase {
    
    func testAlbumCover_coverAlbumInRubbish_shouldUseLatestModifiedPhoto() async throws {
        let cover = NodeEntity(name: "test.jpg", handle: 1)
        let album = AlbumEntity(id: 4, coverNode: cover, type: .user)
        let expectedCover = NodeEntity(handle: 23, modificationTime: try "2024-08-06T10:01:04Z".date)
        let photos = try makeAlbumPhotos() + [AlbumPhotoEntity(photo: expectedCover)]
        
        let nodeRepository = MockNodeRepository(isInRubbishBinNodes: [expectedCover])
        let sut = makeSUT(nodeRepository: nodeRepository)
        
        let albumCover = await sut.albumCover(for: album, photos: photos)
        
        XCTAssertEqual(albumCover, expectedCover)
    }
    
    func testAlbumCover_coverAlbumNotInAlbumPhotos_shouldUseLatestModifiedPhoto() async throws {
        let cover = NodeEntity(name: "test.jpg", handle: 1)
        let album = AlbumEntity(id: 4, coverNode: cover, type: .user)
        let expectedCover = NodeEntity(handle: 23, modificationTime: try "2024-08-06T10:01:04Z".date)
        let photos = try makeAlbumPhotos() + [AlbumPhotoEntity(photo: expectedCover)]
        let sut = makeSUT()
        
        let albumCover = await sut.albumCover(for: album, photos: photos)
        
        XCTAssertEqual(albumCover, expectedCover)
    }
    
    func testAlbumCover_albumCoverNotInRubbishAndInAlbumPhotos_shouldReturnAlbumCover() async {
        let expectedCover = NodeEntity(name: "test.jpg", handle: 1)
        let album = AlbumEntity(id: 4, coverNode: expectedCover, type: .user)
        let albumPhoto = AlbumPhotoEntity(photo: expectedCover)
        
        let nodeRepository = MockNodeRepository(isInRubbishBinNodes: [expectedCover])
        let sut = makeSUT(nodeRepository: nodeRepository)
        
        let albumCover = await sut.albumCover(
            for: album, photos: [albumPhoto])
        
        XCTAssertEqual(albumCover, expectedCover)
    }
    
    func testAlbumCover_coverNotSetAndNoAlbumPhotos_shouldReturnNil() async {
        let album = AlbumEntity(id: 4, coverNode: nil, type: .user)
        let sut = makeSUT()
        
        let albumCover = await sut.albumCover(
            for: album, photos: [])
        
        XCTAssertNil(albumCover)
    }
    
    private func makeSUT(
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository()
    ) -> AlbumCoverUseCase {
        AlbumCoverUseCase(
            nodeRepository: nodeRepository)
    }
    
    private func makeAlbumPhotos() throws -> [AlbumPhotoEntity] {
        [AlbumPhotoEntity(photo: NodeEntity(handle: 3, modificationTime: try "2024-08-06T10:01:04Z".date)),
         AlbumPhotoEntity(photo: NodeEntity(handle: 4, modificationTime: try "2024-03-06T14:01:04Z".date)),
         AlbumPhotoEntity(photo: NodeEntity(handle: 8, modificationTime: try "2024-05-06T11:55:04Z".date))]
    }
}
