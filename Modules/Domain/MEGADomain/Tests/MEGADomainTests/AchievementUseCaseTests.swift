import MEGADomain
import MEGADomainMock
import XCTest

final class AchievementUseCaseTests: XCTestCase {
    
    func testGetAchievementStorage_disabled() async {
        let sut = AchievementUseCase(repo: MockAchievementRepository(isAchievementsEnabled: false, storageResult: Measurement(value: 1000, unit: .bytes)))
        do {
            _ = try await sut.getAchievementStorage(by: .addPhone)
            XCTFail("achievementsDisabled error is expected!")
        } catch let error {
            guard let achievementError = error as? AchievementErrorEntity else {
                XCTFail("achievementsDisabled error is expected!")
                return
            }
            XCTAssertEqual(achievementError, .achievementsDisabled)
        }
    }

    func testGetAchievementStorage_enabled_returnsStorageInBytes() async throws {
        let storage = Measurement(value: 1000, unit: UnitInformationStorage.bytes)
        let sut = AchievementUseCase(repo: MockAchievementRepository(isAchievementsEnabled: true, storageResult: storage))

        let result = try await sut.getAchievementStorage(by: .addPhone)

        XCTAssertEqual(result.unit.symbol, UnitInformationStorage.bytes.symbol)
        XCTAssertEqual(result.converted(to: .bytes).value, 1000)
    }
}
