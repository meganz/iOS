import MEGADomain
import MEGADomainMock
import XCTest

final class PublicAlbumUseCaseTests: XCTestCase {
    
    func testPublicAlbumContents_albumLoadedSuccessfully_shouldReturnSharedAlbum() async throws {
        let setElements = [SetElementEntity(handle: 6),
                           SetElementEntity(handle: 45),
                           SetElementEntity(handle: 89)
        ]
        let sharedCollectionEntity = SharedCollectionEntity(set: SetEntity(handle: 5),
                                                                      setElements: setElements)
        let shareAlbumRepository = MockShareAlbumRepository(publicAlbumContentsResult: .success(sharedCollectionEntity))
        let sut = makePublicAlbumUseCase(shareAlbumRepository: shareAlbumRepository)
        
        let publicAlbum = try await sut.publicAlbum(forLink: "public_album_link")
        
        XCTAssertEqual(publicAlbum, sharedCollectionEntity)
    }
    
    func testPublicAlbumContents_albumLoadFailed_shouldThrowError() async {
        let expectedError = SharedCollectionErrorEntity.couldNotBeReadOrDecrypted
        let shareAlbumRepository = MockShareAlbumRepository(publicAlbumContentsResult: .failure(expectedError))
        let sut = makePublicAlbumUseCase(shareAlbumRepository: shareAlbumRepository)
        
        do {
            _ = try await sut.publicAlbum(forLink: "public_album_link")
        } catch let error as SharedCollectionErrorEntity {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Incorrect error caught")
        }
    }
    
    func testPublicPhotosForLink_albumLoadedSuccessfully_shouldReturnPhotosThatDidNotFailToLoad() async {
        let photoOneId = HandleEntity(15)
        let photoTwoId = HandleEntity(4)
        let photoNode = NodeEntity(handle: 2)
        let photoResults: [HandleEntity: Result<NodeEntity, Error>] = [
            photoOneId: .success(photoNode),
            photoTwoId: .failure(SharedPhotoErrorEntity.photoNotFound)
        ]
        let photoElements = [SetElementEntity(handle: photoOneId),
                             SetElementEntity(handle: photoTwoId)]
        let shareAlbumRepository = MockShareAlbumRepository(publicPhotoResults: photoResults)
        let sut = makePublicAlbumUseCase(shareAlbumRepository: shareAlbumRepository)
        
        let photos = await sut.publicPhotos(photoElements)
        
        XCTAssertEqual(photos, [photoNode])
    }
    
    func testStopAlbumLinkPreview_called_shouldStopAlbumLinkPreview() {
        let shareAlbumRepository = MockShareAlbumRepository()
        let sut = makePublicAlbumUseCase(shareAlbumRepository: shareAlbumRepository)
        
        sut.stopAlbumLinkPreview()
        
        XCTAssertEqual(shareAlbumRepository.stopAlbumLinkPreviewCalled, 1)
    }
    
    // MARK: - Helpers
    
    private func makePublicAlbumUseCase(shareAlbumRepository: some ShareAlbumRepositoryProtocol = MockShareAlbumRepository()
    ) -> some PublicAlbumUseCaseProtocol {
        PublicAlbumUseCase(shareAlbumRepository: shareAlbumRepository)
    }
}
