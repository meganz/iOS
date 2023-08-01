import MEGADomain
import MEGADomainMock
import XCTest

final class SaveAlbumToFolderUseCaseTests: XCTestCase {
    private let parentFolder = NodeEntity(handle: 1, isFolder: true)
    
    func testSaveToFolder_folderCreationFailed_shouldThrowError() async {
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .failure(GenericErrorEntity()))
        let sut = makeSaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository)
        
        await XCTAsyncAssertThrowsError(try await sut.saveToFolder(albumName: "New Album",
                                                                   photos: [],
                                                                   parent: parentFolder)
        ) { errorThrown in
            XCTAssertTrue(errorThrown is GenericErrorEntity)
        }
    }
    
    func testSaveToFolder_onFolderCreation_shouldCopyPublicPhotos() async throws {
        let albumName = "New Album (1)"
        let albumFolder = NodeEntity(name: albumName, handle: 64, isFolder: true)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(albumFolder))
        let copiedPhotos = makePhotos()
        let shareAlbumRepository = MockShareAlbumRepository(copyPublicPhotosResult: .success(copiedPhotos))
        let sut = makeSaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareAlbumRepository: shareAlbumRepository)
        
        let photos = try await sut.saveToFolder(albumName: albumName,
                                                photos: makePhotos(),
                                                parent: parentFolder)
        XCTAssertEqual(photos, copiedPhotos)
    }
    
    func testSaveToFolder_onCopyPhotosFailed_shouldThrowError() async {
        let albumName = "New Album (1)"
        let albumFolder = NodeEntity(name: albumName, handle: 64, isFolder: true)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(albumFolder))
        let failure = CopyOrMoveErrorEntity.nodeCopyFailed
        let shareAlbumRepository = MockShareAlbumRepository(copyPublicPhotosResult: .failure(failure))
        let sut = makeSaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareAlbumRepository: shareAlbumRepository)
        
        await XCTAsyncAssertThrowsError(try await sut.saveToFolder(albumName: "New Album",
                                                                   photos: makePhotos(),
                                                                   parent: parentFolder)
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? CopyOrMoveErrorEntity, failure)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSaveAlbumToFolderUseCase(
        nodeActionRepository: some NodeActionRepositoryProtocol = MockNodeActionRepository(),
        shareAlbumRepository: some ShareAlbumRepositoryProtocol = MockShareAlbumRepository()
    ) -> some SaveAlbumToFolderUseCaseProtocol {
        SaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                 shareAlbumRepository: shareAlbumRepository)
    }
    
    private func makePhotos(count: Int = 4) -> [NodeEntity] {
        Array(repeating: NodeEntity(handle: HandleEntity.random(), mediaType: .image),
              count: count)
    }
}
