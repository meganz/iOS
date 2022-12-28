import XCTest
import MEGADomain
import MEGADomainMock

final class AchievementUseCaseTests: XCTestCase {
    
    func testGetAchievementStorage_disabled() {
        let sut = AchievementUseCase(repo: MockAchievementRepository(isAchievementsEnabled: false, storageResult: .success(.bytes(of: 1000))))
        sut.getAchievementStorage(by: .addPhone) { result in
            switch result {
            case .success:
                XCTFail("achievementsDisabled error is expected!")
            case .failure(let error):
                XCTAssertEqual(error, .achievementsDisabled)
            }
        }
    }
}
