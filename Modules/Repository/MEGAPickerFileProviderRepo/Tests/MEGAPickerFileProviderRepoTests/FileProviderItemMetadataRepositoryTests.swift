import MEGAPickerFileProviderRepo
import XCTest

final class FileProviderItemMetadataRepositoryTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()

        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        if let tempDirectory = tempDirectory {
            try FileManager.default.removeItem(at: tempDirectory)
        }
    }

    func testSetFavoriteRank_whenSetsNewRankNumber_successfullySaves() throws {
        let sut = FileProviderItemMetadataRepository(storageDirectoryURL: tempDirectory)
        let identifier = NSFileProviderItemIdentifier(rawValue: "Mock")
        let rank = NSNumber(value: 1)

        sut.setFavoriteRank(for: identifier, with: rank)

        let result = sut.favoriteRank(for: identifier)

        XCTAssertEqual(rank, result)
    }

    func testFavoriteRank_whenFetchesInexistentRank_shouldReturnNil() throws {
        let sut = FileProviderItemMetadataRepository(storageDirectoryURL: tempDirectory)
        let identifier = NSFileProviderItemIdentifier(rawValue: "Mock")

        let result = sut.favoriteRank(for: identifier)

        XCTAssertNil(result)
    }

    func testSetTagData_whenSetsNewTagData_successfullySaves() throws {
        let sut = FileProviderItemMetadataRepository(storageDirectoryURL: tempDirectory)
        let identifier = NSFileProviderItemIdentifier(rawValue: "Mock")
        let mockData = Data(repeating: 1, count: 1)

        sut.setTagData(for: identifier, with: mockData)

        let result = sut.tagData(for: identifier)

        XCTAssertEqual(mockData, result)
    }

    func testTagData_whenFetchesInexistentTagData_shouldReturnNil() throws {
        let sut = FileProviderItemMetadataRepository(storageDirectoryURL: tempDirectory)
        let identifier = NSFileProviderItemIdentifier(rawValue: "Mock")

        let result = sut.tagData(for: identifier)

        XCTAssertNil(result)
    }

    func testSetFavoriteRank_whenSetsNewRank_andPreviousTagDataExists_shouldNotOverwriteTagData() throws {
        let sut = FileProviderItemMetadataRepository(storageDirectoryURL: tempDirectory)
        let identifier = NSFileProviderItemIdentifier(rawValue: "Mock")
        let mockData = Data(repeating: 1, count: 1)
        let rank = NSNumber(value: 1)

        sut.setTagData(for: identifier, with: mockData)
        sut.setFavoriteRank(for: identifier, with: rank)

        let resultTagData = sut.tagData(for: identifier)
        XCTAssertEqual(mockData, resultTagData)

        let resultRank = sut.favoriteRank(for: identifier)
        XCTAssertEqual(rank, resultRank)
    }
}
