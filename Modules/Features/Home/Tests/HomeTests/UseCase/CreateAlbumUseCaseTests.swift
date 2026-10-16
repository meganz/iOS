import Combine
@testable import Home
import MEGADomain
import MEGADomainMock
import Testing

@Suite("CreateAlbumUseCase")
struct CreateAlbumUseCaseTests {
    @Test("over disk quota follows the paywall state", arguments: [true, false])
    func overDiskQuotaFollowsPaywall(isPaywalled: Bool) {
        let sut = makeSUT(isPaywalled: isPaywalled)

        #expect(sut.isOverDiskQuota == isPaywalled)
    }

    @Test("create returns the created album")
    func createReturnsAlbum() async throws {
        let sut = makeSUT()

        let album = try await sut.createAlbum(named: "Trip")

        #expect(album.name == "Trip")
    }

    @Test("create failure passes the album error on")
    func createFailurePassesErrorOn() async {
        let sut = makeSUT(albumListUseCase: FailingAlbumListUseCase())

        await #expect(throws: AlbumErrorEntity.generic) {
            try await sut.createAlbum(named: "Trip")
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        isPaywalled: Bool = false,
        albumListUseCase: some AlbumListUseCaseProtocol = MockAlbumListUseCase()
    ) -> CreateAlbumUseCase {
        CreateAlbumUseCase(
            accountStorageUseCase: MockAccountStorageUseCase(isPaywalled: isPaywalled),
            albumNameUseCase: MockAlbumNameUseCase(),
            albumListUseCase: albumListUseCase
        )
    }
}

private struct FailingAlbumListUseCase: AlbumListUseCaseProtocol {
    var albumsUpdatedPublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }

    func systemAlbums() async throws -> [AlbumEntity] { [] }

    func userAlbums() async -> [AlbumEntity] { [] }

    func createUserAlbum(with name: String?) async throws -> AlbumEntity {
        throw AlbumErrorEntity.generic
    }

    func hasNoVisualMedia() async -> Bool { false }
}
