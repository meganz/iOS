import MEGADomain
import MEGADomainMock
import XCTest

class ShareCollectionUseCaseTests: XCTestCase {
    func testShareAlbum_onUserAlbum_shouldReturnPublicLink() async throws {
        let expectedLink = "public_link"
        let album = SetEntity(handle: 5, setType: .album)
        let repository = MockShareCollectionRepository(shareCollectionResults: [ album.setIdentifier: .success(expectedLink) ])
        let sut = sut(shareAlbumRepository: repository)
        let result = try await sut.shareCollectionLink(album)
        XCTAssertEqual(result, expectedLink)
    }
    
    func testShareLinksForAlbum_onAllLinksSuccessfullyRetrieved_shouldReturnAllLinksWithHandles() async throws {
        let firstAlbumPublicLink = "public_link"
        let secondAlbumPublicLink = "public_link_2"
        let firstUserAlbum = SetEntity(handle: 5, setType: .album)
        let secondUserAlbum = SetEntity(handle: 6, setType: .album)
        let shareAlbumResults: [SetIdentifier: Result<String?, any Error>] = [
            firstUserAlbum.setIdentifier: .success(firstAlbumPublicLink),
            secondUserAlbum.setIdentifier: .success(secondAlbumPublicLink)]
        let repository = MockShareCollectionRepository(shareCollectionResults: shareAlbumResults)
       
        let sut = sut(shareAlbumRepository: repository)
        let albums = [firstUserAlbum, secondUserAlbum]
        let result = await sut.shareLink(forCollections: albums)
        XCTAssertEqual(result[firstUserAlbum.setIdentifier], firstAlbumPublicLink)
        XCTAssertEqual(result[secondUserAlbum.setIdentifier], secondAlbumPublicLink)
    }
    
    func testShareLinksForAlbum_onFailedLink_shouldReturnOnlySuccessfulLinks() async throws {
        let firstAlbumPublicLink = "public_link"
        let firstUserAlbum = SetEntity(handle: 5, setType: .album)
        let secondUserAlbum = SetEntity(handle: 6, setType: .album)
        let shareAlbumResults: [SetIdentifier: Result<String?, any Error>] = [
            firstUserAlbum.setIdentifier: .success(firstAlbumPublicLink),
            secondUserAlbum.setIdentifier: .failure(GenericErrorEntity())]
        let repository = MockShareCollectionRepository(shareCollectionResults: shareAlbumResults)
       
        let sut = sut(shareAlbumRepository: repository)
        let albums = [firstUserAlbum, secondUserAlbum]
        let result = await sut.shareLink(forCollections: albums)
        XCTAssertEqual(result[firstUserAlbum.setIdentifier], firstAlbumPublicLink)
        XCTAssertNil(result[secondUserAlbum.setIdentifier])
    }
    
    func testDisableShare_onUserAlbum_shouldComplete() async throws {
        let repository = MockShareCollectionRepository(disableCollectionShareResult: .success)
        let sut = sut(shareAlbumRepository: repository)
        try await sut.removeSharedLink(forCollectionId: SetEntity(handle: 5, setType: .album).id)
    }
    
    func testRemoveSharedLink_onMultipleUserAlbum_shouldComplete() async {
        let repository = MockShareCollectionRepository(disableCollectionShareResult: .success)
        let sut = sut(shareAlbumRepository: repository)
        let albums = [SetEntity(handle: 5, setType: .album), SetEntity(handle: 6, setType: .album)]
        let albumIds = await sut.removeSharedLink(forCollections: albums.map { $0.setIdentifier })
        XCTAssertEqual(Set(albums.map { $0.id }), Set(albumIds))
    }
    
    func testDoesAlbumsContainSensitiveElement_albumContainsSensitiveNode_shouldReturnTrue() async throws {
        let albums: [HandleEntity: [AlbumPhotoIdEntity]] = [
            1: [AlbumPhotoIdEntity(albumId: 1, albumPhotoId: 1, nodeId: 1)]
        ]
        let node = NodeEntity(handle: 1)
        let sut = sut(
            userAlbumRepository: MockUserAlbumRepository(albumElementIds: albums),
            nodeRepository: MockNodeRepository(
                node: node,
                isInheritingSensitivityResults: [node: .success(true)]))
        
        let albumsToTest = [
            SetEntity(handle: 1, setType: .album)
        ]
        let result = try await sut.doesCollectionsContainSensitiveElement(for: albumsToTest)
        XCTAssertTrue(result)
    }
    
    func testDoesAlbumsContainSensitiveElement_albumDoesNotContainsSensitiveNode_shouldReturnFalse() async throws {
        let albums: [HandleEntity: [AlbumPhotoIdEntity]] = [
            1: [AlbumPhotoIdEntity(albumId: 1, albumPhotoId: 1, nodeId: 1)]
        ]
        let node = NodeEntity(handle: 1)
        let sut = sut(
            userAlbumRepository: MockUserAlbumRepository(albumElementIds: albums),
            nodeRepository: MockNodeRepository(
                node: node,
                isInheritingSensitivityResults: [node: .success(false)]))
        
        let albumsToTest = [
            SetEntity(handle: 1, setType: .album)
        ]
        let result = try await sut.doesCollectionsContainSensitiveElement(for: albumsToTest)
        XCTAssertFalse(result)
    }
    
    func testDoesAlbumsContainSensitiveElement_whenNoAlbumsProvided_shouldReturnFalse() async throws {
        let sut = sut()
        let result = try await sut.doesCollectionsContainSensitiveElement(for: [])
        XCTAssertFalse(result)
    }
}

extension ShareCollectionUseCaseTests {
    private func sut(
        shareAlbumRepository: some ShareCollectionRepositoryProtocol = MockShareCollectionRepository(),
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        nodeRepository: some NodeRepositoryProtocol = MockNodeRepository()
    ) -> ShareCollectionUseCase {
        ShareCollectionUseCase(
            shareAlbumRepository: shareAlbumRepository,
            userAlbumRepository: userAlbumRepository,
            nodeRepository: nodeRepository
        )
    }
}
