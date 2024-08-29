import MEGADomain
import MEGADomainMock
import XCTest

class ShareCollectionUseCaseTests: XCTestCase {
    func testShareAlbum_onNonUserAlbum_shouldThrowInvalidAlbumType() async {
        let sut = sut(shareAlbumRepository: MockShareCollectionRepository())
        do {
            _ = try await sut.shareCollectionLink(AlbumEntity(id: 2, type: .favourite))
        } catch {
            XCTAssertEqual(error as? ShareCollectionErrorEntity,
                           ShareCollectionErrorEntity.invalidCollectionType)
        }
    }
    
    func testShareAlbum_onUserAlbum_shouldReturnPublicLink() async throws {
        let expectedLink = "public_link"
        let album = AlbumEntity(id: 5, type: .user)
        let repository = MockShareCollectionRepository(shareCollectionResults: [album.id: .success(expectedLink)])
        let sut = sut(shareAlbumRepository: repository)
        let result = try await sut.shareCollectionLink(album)
        XCTAssertEqual(result, expectedLink)
    }
    
    func testShareLinksForAlbum_onAllLinksSuccessfullyRetrieved_shouldReturnAllLinksWithHandles() async throws {
        let firstAlbumPublicLink = "public_link"
        let secondAlbumPublicLink = "public_link_2"
        let firstUserAlbum = AlbumEntity(id: 5, type: .user)
        let secondUserAlbum = AlbumEntity(id: 6, type: .user)
        let shareAlbumResults: [HandleEntity: Result<String?, Error>] = [
            firstUserAlbum.id: .success(firstAlbumPublicLink),
            secondUserAlbum.id: .success(secondAlbumPublicLink)]
        let repository = MockShareCollectionRepository(shareCollectionResults: shareAlbumResults)
       
        let sut = sut(shareAlbumRepository: repository)
        let albums = [firstUserAlbum, secondUserAlbum]
        let result = await sut.shareLink(forAlbums: albums)
        XCTAssertEqual(result[firstUserAlbum.id], firstAlbumPublicLink)
        XCTAssertEqual(result[secondUserAlbum.id], secondAlbumPublicLink)
    }
    
    func testShareLinksForAlbum_onFailedLink_shouldReturnOnlySuccessfulLinks() async throws {
        let firstAlbumPublicLink = "public_link"
        let firstUserAlbum = AlbumEntity(id: 5, type: .user)
        let secondUserAlbum = AlbumEntity(id: 6, type: .user)
        let shareAlbumResults: [HandleEntity: Result<String?, Error>] = [
            firstUserAlbum.id: .success(firstAlbumPublicLink),
            secondUserAlbum.id: .failure(GenericErrorEntity())]
        let repository = MockShareCollectionRepository(shareCollectionResults: shareAlbumResults)
       
        let sut = sut(shareAlbumRepository: repository)
        let albums = [firstUserAlbum, secondUserAlbum]
        let result = await sut.shareLink(forAlbums: albums)
        XCTAssertEqual(result[firstUserAlbum.id], firstAlbumPublicLink)
        XCTAssertNil(result[secondUserAlbum.id])
    }
    
    func testDisableShare_onNonUserAlbum_shouldThrowInvalidAlbumType() async {
        let sut = sut(shareAlbumRepository: MockShareCollectionRepository())
        do {
            try await sut.removeSharedLink(forAlbum: AlbumEntity(id: 2, type: .favourite))
        } catch {
            XCTAssertEqual(error as? ShareCollectionErrorEntity,
                           ShareCollectionErrorEntity.invalidCollectionType)
        }
    }
    
    func testDisableShare_onUserAlbum_shouldComplete() async throws {
        let repository = MockShareCollectionRepository(disableCollectionShareResult: .success)
        let sut = sut(shareAlbumRepository: repository)
        try await sut.removeSharedLink(forAlbum: AlbumEntity(id: 5, type: .user))
    }
    
    func testRemoveSharedLink_onMultipleUserAlbum_shouldComplete() async {
        let repository = MockShareCollectionRepository(disableCollectionShareResult: .success)
        let sut = sut(shareAlbumRepository: repository)
        let albums = [AlbumEntity(id: 5, type: .user), AlbumEntity(id: 6, type: .user)]
        let albumIds = await sut.removeSharedLink(forAlbums: albums)
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
            AlbumEntity(id: 1, type: .user)
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
            AlbumEntity(id: 1, type: .user)
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
