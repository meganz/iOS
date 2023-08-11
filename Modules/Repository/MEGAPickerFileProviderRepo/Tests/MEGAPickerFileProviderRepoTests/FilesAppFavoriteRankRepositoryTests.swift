import MEGAPickerFileProviderRepo
import XCTest

final class FilesAppFavoriteRankRepositoryTests: XCTestCase {
    private static var mockUserDefaults: UserDefaults {
        guard let userDefaults = UserDefaults(suiteName: #file) else {
            fatalError("Unable to create mock user defaults, terminating test suite")
        }

        return userDefaults
    }

    override func setUp() {
        super.setUp()
        Self.mockUserDefaults.removePersistentDomain(forName: #file)
    }

    override func tearDownWithError() throws {
        super.tearDown()

        // Mocking user defaults generates a bloat `.plist` file, so we ought to remove it in order to not
        // pollute the repository
        var bloatPlistFilePath = URL(fileURLWithPath: #file)
        bloatPlistFilePath.appendPathExtension("plist")

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: bloatPlistFilePath.path) {
            try fileManager.removeItem(at: bloatPlistFilePath)
        }
    }

    func testSetFavoriteRank_whenSetsNewRankNumber_successfullySaves() throws {
        let sut = FilesAppFavoriteRankRepository(storage: Self.mockUserDefaults)
        let identifier = NSFileProviderItemIdentifier(rawValue: "Mock")
        let rank = NSNumber(value: 1)

        sut.setFavoriteRank(for: identifier, with: rank)

        let result = sut.favoriteRank(for: identifier)

        XCTAssertEqual(rank, result)
    }

    func testFavoriteRank_whenFetchesInexistentRank_shouldReturnNil() throws {
        let sut = FilesAppFavoriteRankRepository(storage: Self.mockUserDefaults)
        let identifier = NSFileProviderItemIdentifier(rawValue: "Mock")

        let result = sut.favoriteRank(for: identifier)

        XCTAssertNil(result)
    }
}
