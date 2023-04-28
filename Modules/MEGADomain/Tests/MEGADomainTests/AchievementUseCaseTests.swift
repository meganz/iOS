import XCTest
import MEGADomain
import MEGADomainMock

final class AchievementUseCaseTests: XCTestCase {
    
    func testGetAchievementStorage_disabled() async {
        let sut = AchievementUseCase(repo: MockAchievementRepository(isAchievementsEnabled: false, storageResult: .bytes(of: 1000)))
        do {
            let _ = try await sut.getAchievementStorage(by: .addPhone)
            XCTFail("achievementsDisabled error is expected!")
        } catch let error {
            guard let achievementError = error as? AchievementErrorEntity else {
                XCTFail("achievementsDisabled error is expected!")
                return
            }
            XCTAssertEqual(achievementError, .achievementsDisabled)
        }
    }
}
