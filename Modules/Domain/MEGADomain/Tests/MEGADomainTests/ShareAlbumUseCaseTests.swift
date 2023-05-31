import XCTest
import MEGADomain
import MEGADomainMock

class ShareAlbumUseCaseTests: XCTestCase {
    func testShareAlbum_onNonUserAlbum_shouldThrowInvalidAlbumType() async {
        let sut = ShareAlbumUseCase(shareAlbumRepository: MockShareAlbumRepository())
        do {
            _ = try await sut.shareAlbumLink(AlbumEntity(id: 2, type: .favourite))
        } catch {
            XCTAssertEqual(error as? ShareAlbumErrorEntity,
                           ShareAlbumErrorEntity.invalidAlbumType)
        }
    }
    
    func testShareAlbum_onUserAlbum_shouldReturnPublicLink() async throws {
        let expectedLink = "public_link"
        let album = AlbumEntity(id: 5, type: .user)
        let repository = MockShareAlbumRepository(shareAlbumResults: [album.id: .success(expectedLink)])
        let sut = ShareAlbumUseCase(shareAlbumRepository: repository)
        let result = try await sut.shareAlbumLink(album)
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
        let repository = MockShareAlbumRepository(shareAlbumResults: shareAlbumResults)
       
        let sut = ShareAlbumUseCase(shareAlbumRepository: repository)
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
        let repository = MockShareAlbumRepository(shareAlbumResults: shareAlbumResults)
       
        let sut = ShareAlbumUseCase(shareAlbumRepository: repository)
        let albums = [firstUserAlbum, secondUserAlbum]
        let result = await sut.shareLink(forAlbums: albums)
        XCTAssertEqual(result[firstUserAlbum.id], firstAlbumPublicLink)
        XCTAssertNil(result[secondUserAlbum.id])
    }
    
    func testDisableShare_onNonUserAlbum_shouldThrowInvalidAlbumType() async {
        let sut = ShareAlbumUseCase(shareAlbumRepository: MockShareAlbumRepository())
        do {
            try await sut.removeSharedLink(forAlbum: AlbumEntity(id: 2, type: .favourite))
        } catch {
            XCTAssertEqual(error as? ShareAlbumErrorEntity,
                           ShareAlbumErrorEntity.invalidAlbumType)
        }
    }
    
    func testDisableShare_onUserAlbum_shouldComplete() async throws {
        let repository = MockShareAlbumRepository(disableAlbumShareResult: .success)
        let sut = ShareAlbumUseCase(shareAlbumRepository: repository)
        try await sut.removeSharedLink(forAlbum: AlbumEntity(id: 5, type: .user))
    }
    
    func testRemoveSharedLink_onMultipleUserAlbum_shouldComplete() async {
        let repository = MockShareAlbumRepository(disableAlbumShareResult: .success)
        let sut = ShareAlbumUseCase(shareAlbumRepository: repository)
        let albums = [AlbumEntity(id: 5, type: .user), AlbumEntity(id: 6, type: .user)]
        let albumIds = await sut.removeSharedLink(forAlbums: albums)
        XCTAssertEqual(Set(albums.map { $0.id }), Set(albumIds))
    }
}
