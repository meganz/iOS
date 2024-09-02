import MEGADomain
import MEGADomainMock
import XCTest

final class PublicCollectionUseCaseTests: XCTestCase {
    
    func testPublicCollectionContents_collectionLoadedSuccessfully_shouldReturnSharedCollection() async throws {
        let setElements = [SetElementEntity(handle: 6),
                           SetElementEntity(handle: 45),
                           SetElementEntity(handle: 89)
        ]
        let sharedCollectionEntity = SharedCollectionEntity(set: SetEntity(handle: 5),
                                                                      setElements: setElements)
        let shareCollectionRepository = MockShareCollectionRepository(publicCollectionContentsResult: .success(sharedCollectionEntity))
        let sut = makePublicCollectionUseCase(shareCollectionRepository: shareCollectionRepository)
        
        let publicCollection = try await sut.publicCollection(forLink: "public_collection_link")
        
        XCTAssertEqual(publicCollection, sharedCollectionEntity)
    }
    
    func testPublicCollectionContents_collectionLoadFailed_shouldThrowError() async {
        let expectedError = SharedCollectionErrorEntity.couldNotBeReadOrDecrypted
        let shareCollectionRepository = MockShareCollectionRepository(publicCollectionContentsResult: .failure(expectedError))
        let sut = makePublicCollectionUseCase(shareCollectionRepository: shareCollectionRepository)
        
        do {
            _ = try await sut.publicCollection(forLink: "public_collection_link")
        } catch let error as SharedCollectionErrorEntity {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Incorrect error caught")
        }
    }
    
    func testPublicPhotosForLink_collectionLoadedSuccessfully_shouldReturnPhotosThatDidNotFailToLoad() async {
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
        let sut = makePublicCollectionUseCase(shareCollectionRepository: shareCollectionRepository)
        
        let photos = await sut.publicNodes(photoElements)
        
        XCTAssertEqual(photos, [photoNode])
    }
    
    func testStopCollectionLinkPreview_called_shouldStopCollectionLinkPreview() {
        let shareCollectionRepository = MockShareCollectionRepository()
        let sut = makePublicCollectionUseCase(shareCollectionRepository: shareCollectionRepository)
        
        sut.stopCollectionLinkPreview()
        
        XCTAssertEqual(shareCollectionRepository.stopCollectionLinkPreviewCalled, 1)
    }
    
    // MARK: - Helpers
    
    private func makePublicCollectionUseCase(shareCollectionRepository: some ShareCollectionRepositoryProtocol = MockShareCollectionRepository()
    ) -> some PublicCollectionUseCaseProtocol {
        PublicCollectionUseCase(shareCollectionRepository: shareCollectionRepository)
    }
}
