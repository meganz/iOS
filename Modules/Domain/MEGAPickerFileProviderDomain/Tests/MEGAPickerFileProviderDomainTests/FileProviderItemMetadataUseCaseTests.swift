import MEGAPickerFileProviderDomain
import XCTest

final class FileProviderItemMetadataUseCaseTests: XCTestCase {
    private static let mockIdentifier = NSFileProviderItemIdentifier("Mock")
    private static let mockRank = NSNumber(value: 1)
    private static let mockData = Data(repeating: 1, count: 1)

    func testSetFavoriteRank_whenSetsNewRankNumber_successfullyCallsRepositoryWithCorrectIdentifierAndNumber() throws {
        let sut = FileProviderItemMetadataUseCase(repository: MockFileProviderItemMetadataRepository.newRepo)

        sut.setFavoriteRank(for: Self.mockIdentifier, with: Self.mockRank)
    }

    func testFavoriteRank_whenFetchesRank_successfullyCallsRepositoryWithCorrectIdentifier() throws {
        let sut = FileProviderItemMetadataUseCase(repository: MockFileProviderItemMetadataRepository.newRepo)

        _ = sut.favoriteRank(for: Self.mockIdentifier)
    }

    func testSetTagData_whenSetsNewTagData_successfullyCallsRepositoryWithCorrectIdentifierAndNumber() throws {
        let sut = FileProviderItemMetadataUseCase(repository: MockFileProviderItemMetadataRepository.newRepo)

        sut.setTagData(for: Self.mockIdentifier, with: Self.mockData)
    }

    func testTagData_whenFetchesTagData_successfullyCallsRepositoryWithCorrectIdentifier() throws {
        let sut = FileProviderItemMetadataUseCase(repository: MockFileProviderItemMetadataRepository.newRepo)

        _ = sut.tagData(for: Self.mockIdentifier)
    }
}

private extension FileProviderItemMetadataUseCaseTests {
    struct MockFileProviderItemMetadataRepository: FileProviderItemMetadataRepositoryProtocol {
        static var newRepo: MockFileProviderItemMetadataRepository {
            MockFileProviderItemMetadataRepository()
        }

        func favoriteRank(for identifier: NSFileProviderItemIdentifier) -> NSNumber? {
            XCTAssertEqual(identifier, FileProviderItemMetadataUseCaseTests.mockIdentifier)
            return nil
        }

        func setFavoriteRank(for identifier: NSFileProviderItemIdentifier, with rank: NSNumber?) {
            XCTAssertEqual(identifier, FileProviderItemMetadataUseCaseTests.mockIdentifier)
            XCTAssertEqual(rank, FileProviderItemMetadataUseCaseTests.mockRank)
        }

        func tagData(for identifier: NSFileProviderItemIdentifier) -> Data? {
            XCTAssertEqual(identifier, FileProviderItemMetadataUseCaseTests.mockIdentifier)
            return nil
        }

        func setTagData(for identifier: NSFileProviderItemIdentifier, with data: Data?) {
            XCTAssertEqual(identifier, FileProviderItemMetadataUseCaseTests.mockIdentifier)
            XCTAssertEqual(data, FileProviderItemMetadataUseCaseTests.mockData)
        }
    }
}
