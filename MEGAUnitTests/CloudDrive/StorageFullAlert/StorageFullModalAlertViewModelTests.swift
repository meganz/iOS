@testable import MEGA
import XCTest

final class StorageFullModalAlertViewModelTests: XCTestCase {

    @MainActor
    func testRequiredStorageMemoryStyleString_whenInvoked_shouldMatchResults() {
        let sut = makeSUT()
        XCTAssertEqual(sut.requiredStorageMemoryStyleString, "100 bytes")
    }

    @MainActor
    func testShouldShowAlert_whenFreeSizeExceeds_shouldReturnFalse() async {
        let sut = makeSUT(fileManager: MockFileManager(freeSize: 100 * 1024 * 1024))
        let result = await sut.shouldShowAlert()
        XCTAssertFalse(result)
    }

    @MainActor
    func testShouldShowAlert_lastSavedYesterday_shouldReturnFalse() async {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let userDefaults = MockUserDefaults(doubleValue: yesterday.timeIntervalSince1970)!
        let sut = makeSUT(userDefaults: userDefaults)
        let result = await sut.shouldShowAlert()
        XCTAssertFalse(result)
    }

    @MainActor
    func testShouldShowAlert_freeSizeDoesNotExceedAndlastSaveGreaterThanTwo_shouldReturnTrue() async {
        let yesterday = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
        let userDefaults = MockUserDefaults(doubleValue: yesterday.timeIntervalSince1970)!
        let sut = makeSUT(fileManager: MockFileManager(freeSize: 1000), userDefaults: userDefaults)
        let result = await sut.shouldShowAlert()
        XCTAssertTrue(result)
    }

    @MainActor
    func testUpdateLastStoredDate_whenInvoked_shouldStoreTheDate() {
        let userDefaults = MockUserDefaults()!
        let sut = makeSUT(userDefaults: userDefaults)
        let date = Date.now
        sut.update(lastStoredDate: date)
        XCTAssertEqual(userDefaults.doubleValue, date.timeIntervalSince1970)
    }

    // MARK: - Helper

    @MainActor
    private func makeSUT(
        routing: some StorageFullModalAlertViewRouting = MockStorageFullModalAlertViewRouter(),
        requiredStorage: Int64 = 100,
        fileManager: FileManager = MockFileManager(),
        userDefaults: UserDefaults = MockUserDefaults() ?? .standard
    ) -> StorageFullModalAlertViewModel {
        let sut = StorageFullModalAlertViewModel(
            routing: routing,
            requiredStorage: requiredStorage,
            fileManager: fileManager,
            userDefaults: userDefaults
        )
        trackForMemoryLeaks(on: sut)
        return sut
    }
}

private final class MockFileManager: FileManager {
    private let freeSize: UInt64

    init(freeSize: UInt64 = 100) {
        self.freeSize = freeSize
        super.init()
    }

    override var mnz_fileSystemFreeSize: UInt64 {
        freeSize
    }
}

private final class MockUserDefaults: UserDefaults {
    var doubleValue: Double

    init?(doubleValue: Double = 0.0) {
        self.doubleValue = doubleValue
        super.init(suiteName: nil)
    }

    override func double(forKey defaultName: String) -> Double {
        doubleValue
    }

    override func set(_ value: Double, forKey defaultName: String) {
        doubleValue = value
    }
}
