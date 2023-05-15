import XCTest
import MEGADomain
import MEGADataMock
import MEGASdk

final class AchievementsDetailsEntityMappingTests: XCTestCase {
    func testAchievementDetailsEntity_onNoAwards_shouldNotHaveAwardClasses() {
        let details = MockMEGAAchievementDetails(ahievementAwardsCount: 0).toAchievementDetailsEntity()
        XCTAssertTrue(details.awardsCount == 0)
    }

    func testAchievementDetailsEntity_onHasAwards_shouldHaveAwardClasses() {
        let details = MockMEGAAchievementDetails(ahievementAwardsCount: 1).toAchievementDetailsEntity()
        XCTAssertTrue(details.awardsCount == 1)
    }
}
