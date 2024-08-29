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
        let shareCollectionRepository = MockShareCollectionRepository(publicCollectionContentsResult: .success(sharedCollectionEntity))
        let sut = makePublicAlbumUseCase(shareCollectionRepository: shareCollectionRepository)
        
        let publicAlbum = try await sut.publicAlbum(forLink: "public_album_link")
        
        XCTAssertEqual(publicAlbum, sharedCollectionEntity)
    }
    
    func testPublicAlbumContents_albumLoadFailed_shouldThrowError() async {
        let expectedError = SharedCollectionErrorEntity.couldNotBeReadOrDecrypted
        let shareCollectionRepository = MockShareCollectionRepository(publicCollectionContentsResult: .failure(expectedError))
        let sut = makePublicAlbumUseCase(shareCollectionRepository: shareCollectionRepository)
        
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
        let shareCollectionRepository = MockShareCollectionRepository(publicNodeResults: photoResults)
        let sut = makePublicAlbumUseCase(shareCollectionRepository: shareCollectionRepository)
        
        let photos = await sut.publicPhotos(photoElements)
        
        XCTAssertEqual(photos, [photoNode])
    }
    
    func testStopAlbumLinkPreview_called_shouldStopAlbumLinkPreview() {
        let shareCollectionRepository = MockShareCollectionRepository()
        let sut = makePublicAlbumUseCase(shareCollectionRepository: shareCollectionRepository)
        
        sut.stopAlbumLinkPreview()
        
        XCTAssertEqual(shareCollectionRepository.stopCollectionLinkPreviewCalled, 1)
    }
    
    // MARK: - Helpers
    
    private func makePublicAlbumUseCase(shareCollectionRepository: some ShareCollectionRepositoryProtocol = MockShareCollectionRepository()
    ) -> some PublicAlbumUseCaseProtocol {
        PublicAlbumUseCase(shareCollectionRepository: shareCollectionRepository)
    }
}
