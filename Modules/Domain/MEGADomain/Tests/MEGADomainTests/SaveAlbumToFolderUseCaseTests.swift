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
        let shareCollectionRepository = MockShareCollectionRepository(copyPublicNodesResult: .success(copiedPhotos))
        let sut = makeSaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareCollectionRepository: shareCollectionRepository)
        
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
        let shareCollectionRepository = MockShareCollectionRepository(copyPublicNodesResult: .failure(failure))
        let sut = makeSaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareCollectionRepository: shareCollectionRepository)
        
        await XCTAsyncAssertThrowsError(try await sut.saveToFolder(albumName: "New Album",
                                                                   photos: makePhotos(),
                                                                   parent: parentFolder)
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? CopyOrMoveErrorEntity, failure)
        }
    }
    
    func testSaveToFolder_folderExistWithAlbumName_shouldAddSuffixToAlbumName() async throws {
        let albumName = "New Album"
        let childNodes = [albumName: NodeEntity(handle: 5),
                          albumName + " (1)": NodeEntity(handle: 66)]
        let nodeRepository = MockNodeRepository(childNodes: childNodes)
        let expectedFolderName = albumName + " (1) (1)"
        let albumFolder = NodeEntity(name: expectedFolderName, handle: 64, isFolder: true)
        let nodeActionRepository = MockNodeActionRepository(createFolderResult: .success(albumFolder))
        let copiedPhotos = makePhotos()
        let shareCollectionRepository = MockShareCollectionRepository(copyPublicNodesResult: .success(copiedPhotos))
        let sut = makeSaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                               shareCollectionRepository: shareCollectionRepository,
                                               nodeRepository: nodeRepository)
        
        let photos = try await sut.saveToFolder(albumName: albumName,
                                                photos: makePhotos(),
                                                parent: parentFolder)
        XCTAssertEqual(photos, copiedPhotos)
        XCTAssertEqual(nodeActionRepository.createFolderName,
                       expectedFolderName)
    }
    
    // MARK: - Helpers
    
    private func makeSaveAlbumToFolderUseCase(
        nodeActionRepository: some NodeActionRepositoryProtocol = MockNodeActionRepository(),
        shareCollectionRepository: some ShareCollectionRepositoryProtocol = MockShareCollectionRepository(),
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository()
    ) -> some SaveAlbumToFolderUseCaseProtocol {
        SaveAlbumToFolderUseCase(nodeActionRepository: nodeActionRepository,
                                 shareAlbumRepository: shareCollectionRepository,
                                 nodeRepository: nodeRepository)
    }
    
    private func makePhotos(count: Int = 4) -> [NodeEntity] {
        Array(repeating: NodeEntity(handle: HandleEntity.random(), mediaType: .image),
              count: count)
    }
}
