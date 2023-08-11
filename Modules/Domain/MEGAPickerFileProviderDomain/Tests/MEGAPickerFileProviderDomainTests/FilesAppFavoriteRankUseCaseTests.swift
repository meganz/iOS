import MEGAPickerFileProviderDomain
import XCTest

final class FilesAppFavoriteRankUseCaseTests: XCTestCase {
    private static let mockIdentifier = NSFileProviderItemIdentifier("Mock")
    private static let mockRank = NSNumber(value: 1)

    func testSetFavoriteRank_whenSetsNewRankNumber_successfullyCallsRepositoryWithCorrectIdentifierAndNumber() throws {
        let sut = FilesAppFavoriteRankUseCase(repository: MockFilesAppFavoriteRankRepository.newRepo)

        sut.setFavoriteRank(for: Self.mockIdentifier, with: Self.mockRank)
    }

    func testFavoriteRank_whenFetchesRank_successfullyCallsRepositoryWithCorrectIdentifier() throws {
        let sut = FilesAppFavoriteRankUseCase(repository: MockFilesAppFavoriteRankRepository.newRepo)

        _ = sut.favoriteRank(for: Self.mockIdentifier)
    }
}

extension FilesAppFavoriteRankUseCaseTests {
    struct MockFilesAppFavoriteRankRepository: FilesAppFavoriteRankRepositoryProtocol {
        static var newRepo: MockFilesAppFavoriteRankRepository {
            MockFilesAppFavoriteRankRepository()
        }

        func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber? {
            XCTAssertEqual(identifier, FilesAppFavoriteRankUseCaseTests.mockIdentifier)
            return nil
        }

        func setFavoriteRank(for identifier: NSFileProviderItemIdentifier, with rank: NSNumber?) {
            XCTAssertEqual(identifier, FilesAppFavoriteRankUseCaseTests.mockIdentifier)
            XCTAssertEqual(rank, FilesAppFavoriteRankUseCaseTests.mockRank)
        }
    }
}
