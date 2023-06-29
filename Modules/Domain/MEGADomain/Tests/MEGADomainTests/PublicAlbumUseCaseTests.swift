import MEGADomain
import MEGADomainMock
import XCTest

final class PublicAlbumUseCaseTests: XCTestCase {
    
    func testPublicPhotosForLink_albumLoadedSuccessfully_shouldReturnPhotosThatDidNotFailToLoad() async throws {
        let photoId = HandleEntity(15)
        let photoNode = NodeEntity(handle: 2)
        let photoResults: [HandleEntity: Result<NodeEntity, Error>] = [
            photoId: .success(photoNode),
            HandleEntity(4): .failure(SharedPhotoErrorEntity.photoNotFound)
        ]
        let sharedAlbumEntity = SharedAlbumEntity(set: SetEntity(handle: 5),
                                                  setElements: [SetElementEntity(handle: photoId)])
        let shareAlbumRepository = MockShareAlbumRepository(publicAlbumContentsResult: .success(sharedAlbumEntity),
                                                            publicPhotoResults: photoResults)
        let sut = PublicAlbumUseCase(shareAlbumRepository: shareAlbumRepository)
        
        let photos = try await sut.publicPhotos(forLink: "public_album_link")
        
        XCTAssertEqual(photos, [photoNode])
    }
    
    func testPublicPhotosForLink_albumLoadFailed_shouldThrowError() async {
        let expectedError = SharedAlbumErrorEntity.couldNotBeReadOrDecrypted
        let shareAlbumRepository = MockShareAlbumRepository(publicAlbumContentsResult: .failure(expectedError))
        let sut = PublicAlbumUseCase(shareAlbumRepository: shareAlbumRepository)
        
        do {
            _ = try await sut.publicPhotos(forLink: "public_album_link")
        } catch let error as SharedAlbumErrorEntity {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Incorrect error caught")
        }
    }
}
