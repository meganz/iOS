import XCTest
import MEGADomain
import MEGADomainMock

class ShareAlbumUseCaseTests: XCTestCase {
    func testShareAlbum_onNonUserAlbum_shouldThrowInvalidAlbumType() async {
        let sut = ShareAlbumUseCase(shareAlbumRepository: MockShareAlbumRepository())
        do {
            _ = try await sut.shareAlbumLink( AlbumEntity(id: 2, type: .favourite))
        } catch {
            XCTAssertEqual(error as? ShareAlbumErrorEntity,
                           ShareAlbumErrorEntity.invalidAlbumType)
        }
    }
    
    func testShareAlbum_onUserAlbum_shouldReturnPublicLink() async throws {
        let expectedLink = "public_link"
        let repository = MockShareAlbumRepository(shareAlbumResult: .success(expectedLink))
        let sut = ShareAlbumUseCase(shareAlbumRepository: repository)
        let result = try await sut.shareAlbumLink( AlbumEntity(id: 5, type: .user))
        XCTAssertEqual(result, expectedLink)
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
}
