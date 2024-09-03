import MEGADomain
import MEGADomainMock
import XCTest

final class ImportPublicAlbumUseCaseTests: XCTestCase {
    private let albumName = "New Album (10)"
    private let parentFolder = NodeEntity(handle: 1, isFolder: true)
    
    func testImportAlbum_saveFolderFails_shouldThrowException() async {
        let failure = CreateFolderErrorEntity.businessExpired
        let saveCollectionToFolderUseCase = MockSaveCollectionToFolderUseCase(
            saveToFolderResult: .failure(failure))
        let sut = makeImportPublicAlbumUseCase(saveCollectionToFolderUseCase: saveCollectionToFolderUseCase)
        await XCTAsyncAssertThrowsError(try await sut.importAlbum(name: albumName,
                                                                  photos: [],
                                                                  parentFolder: parentFolder)
        ) { errorThrown in
            XCTAssertEqual(errorThrown as? CreateFolderErrorEntity, failure)
        }
    }
    
    func testImportAlbum_onSaveToFolderAndAlbumPhotosAdded_shouldCompleteWithoutError() async throws {
        let photos = makePhotos()
        let saveCollectionToFolderUseCase = MockSaveCollectionToFolderUseCase(
            saveToFolderResult: .success(photos))
        let createdAlbum = SetEntity(handle: 1, name: albumName)
        let addPhotosResult = AlbumElementsResultEntity(success: UInt(photos.count), failure: 0)
        let userRepository = MockUserAlbumRepository(createAlbumResult: .success(createdAlbum),
                                                     addPhotosResult: .success(addPhotosResult))
        let sut = makeImportPublicAlbumUseCase(saveCollectionToFolderUseCase: saveCollectionToFolderUseCase,
                                               userAlbumRepository: userRepository)
        
        try await sut.importAlbum(name: albumName,
                                  photos: photos,
                                  parentFolder: parentFolder)
    }
    
    func testImportAlbum_onAlbumCreationFailed_shouldThrowError() async {
        let saveCollectionToFolderUseCase = MockSaveCollectionToFolderUseCase(
            saveToFolderResult: .success(makePhotos()))
        
        let userRepository = MockUserAlbumRepository(createAlbumResult: .failure(GenericErrorEntity()))
        let sut = makeImportPublicAlbumUseCase(saveCollectionToFolderUseCase: saveCollectionToFolderUseCase,
                                               userAlbumRepository: userRepository)
        
        await XCTAsyncAssertThrowsError(try await sut.importAlbum(name: albumName,
                                                                  photos: makePhotos(),
                                                                  parentFolder: parentFolder)
        ) { errorThrown in
            XCTAssertTrue(errorThrown is GenericErrorEntity)
        }
    }
    
    func testImportAlbum_onAlbumPhotosAddedFailed_shouldThrowError() async {
        let saveCollectionToFolderUseCase = MockSaveCollectionToFolderUseCase(
            saveToFolderResult: .success(makePhotos()))
        
        let userRepository = MockUserAlbumRepository(createAlbumResult: .success(SetEntity(handle: 5)),
                                                     addPhotosResult: .failure(GenericErrorEntity()))
        let sut = makeImportPublicAlbumUseCase(saveCollectionToFolderUseCase: saveCollectionToFolderUseCase,
                                               userAlbumRepository: userRepository)
        
        await XCTAsyncAssertThrowsError(try await sut.importAlbum(name: albumName,
                                                                  photos: makePhotos(),
                                                                  parentFolder: parentFolder)
        ) { errorThrown in
            XCTAssertTrue(errorThrown is GenericErrorEntity)
        }
    }
    
    // MARK: - Helpers
    
    private func makeImportPublicAlbumUseCase(
        saveCollectionToFolderUseCase: some SaveCollectionToFolderUseCaseProtocol = MockSaveCollectionToFolderUseCase(),
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository()
    ) -> some ImportPublicAlbumUseCaseProtocol {
        ImportPublicAlbumUseCase(saveCollectionToFolderUseCase: saveCollectionToFolderUseCase,
                                 userAlbumRepository: userAlbumRepository)
    }
    
    private func makePhotos() -> [NodeEntity] {
        [NodeEntity(handle: HandleEntity.random(), mediaType: .image),
         NodeEntity(handle: HandleEntity.random(), mediaType: .video)]
    }
}
