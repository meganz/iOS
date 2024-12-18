@testable import MEGA
import XCTest

final class StorageFullModalAlertViewModelTests: XCTestCase {

    @MainActor
    func testRequiredStorageMemoryStyleString__with100Bytes_shouldMatchResults() {
        let sut = makeSUT(requiredStorage: 100)
        XCTAssertEqual(sut.requiredStorageMemoryStyleString, "100 bytes")
    }

    @MainActor
    func testRequiredStorageMemoryStyleString__with100KiloBytes_shouldMatchResults() {
        let sut = makeSUT(requiredStorage: 100 * 1024)
        XCTAssertEqual(sut.requiredStorageMemoryStyleString, "100 KB")
    }

    @MainActor
    func testRequiredStorageMemoryStyleString__with1MegaByte_shouldMatchResults() {
        let sut = makeSUT(requiredStorage: 1024 * 1024)
        XCTAssertEqual(sut.requiredStorageMemoryStyleString, "1 MB")
    }

    @MainActor
    func testRequiredStorageMemoryStyleString__with100MegaBytes_shouldMatchResults() {
        let sut = makeSUT(requiredStorage: 100 * 1024 * 1024)
        XCTAssertEqual(sut.requiredStorageMemoryStyleString, "100 MB")
    }

    @MainActor
    func testRequiredStorageMemoryStyleString__with1GigaByte_shouldMatchResults() {
        let sut = makeSUT(requiredStorage: 1024 * 1024 * 1024)
        XCTAssertEqual(sut.requiredStorageMemoryStyleString, "1 GB")
    }

    @MainActor
    func testShouldShowAlert_whenLimitedSpaceAndRequiredStorageIsInconsistent_shouldReturnFalse() async {
        let sut = makeSUT(requiredStorage: 100, limitedSpace: 200)
        let result = await sut.shouldShowAlert()
        XCTAssertFalse(result)
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
        let sut = makeSUT(fileManager: MockFileManager(freeSize: 100), userDefaults: userDefaults)
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
        requiredStorage: Int64 = 1000,
        limitedSpace: Int64 = 750,
        fileManager: FileManager = MockFileManager(),
        userDefaults: UserDefaults = MockUserDefaults() ?? .standard
    ) -> StorageFullModalAlertViewModel {
        let sut = StorageFullModalAlertViewModel(
            routing: routing,
            requiredStorage: requiredStorage,
            limitedSpace: limitedSpace,
            fileManager: fileManager,
            userDefaults: userDefaults
        )
        trackForMemoryLeaks(on: sut)
        return sut
    }
}

private final class MockUserDefaults: UserDefaults, @unchecked Sendable {
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
