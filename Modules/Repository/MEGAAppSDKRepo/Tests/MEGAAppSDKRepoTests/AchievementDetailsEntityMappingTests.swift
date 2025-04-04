import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import XCTest

final class AchievementsDetailsEntityMappingTests: XCTestCase {
    func testAchievementDetailsEntity_onNoAwards_shouldNotHaveAwardClasses() {
        let details = MockMEGAAchievementDetails(achievementAwardsCount: 0).toAchievementDetailsEntity()
        XCTAssertTrue(details.awardsCount == 0)
    }

    func testAchievementDetailsEntity_onHasAwards_shouldHaveAwardClasses() {
        let details = MockMEGAAchievementDetails(achievementAwardsCount: 1).toAchievementDetailsEntity()
        XCTAssertTrue(details.awardsCount == 1)
    }
    
    func testAchievementDetailsEntity_withoutClassStorage_returnsClassStorageDefault() throws {
        let details = MockMEGAAchievementDetails(achievementAwardsCount: 0).toAchievementDetailsEntity()
        details.classStorages.forEach {
            switch $0.achievementType {
            case .welcome: XCTAssertEqual($0.storage, Int64(-1))
            case .invite: XCTAssertEqual($0.storage, Int64(-1))
            case .desktopInstall: XCTAssertEqual($0.storage, Int64(-1))
            case .mobileInstall: XCTAssertEqual($0.storage, Int64(-1))
            case .addPhone: XCTAssertEqual($0.storage, Int64(-1))
            }
        }
    }
    
    func testAchievementDetailsEntity_withoutClassStorage_returnsClassTransferDefault() throws {
        let details = MockMEGAAchievementDetails(achievementAwardsCount: 0).toAchievementDetailsEntity()
        details.classTransfers.forEach {
            switch $0.achievementType {
            case .welcome: XCTAssertEqual($0.transfer, Int64(-1))
            case .invite: XCTAssertEqual($0.transfer, Int64(-1))
            case .desktopInstall: XCTAssertEqual($0.transfer, Int64(-1))
            case .mobileInstall: XCTAssertEqual($0.transfer, Int64(-1))
            case .addPhone: XCTAssertEqual($0.transfer, Int64(-1))
            }
        }
    }
    
    func testAchievementDetailsEntity_withoutClassStorage_returnsClassExpireDefault() throws {
        let details = MockMEGAAchievementDetails(achievementAwardsCount: 0).toAchievementDetailsEntity()
        details.classExpires.forEach {
            switch $0.achievementType {
            case .welcome: XCTAssertEqual($0.expire, -1)
            case .invite: XCTAssertEqual($0.expire, -1)
            case .desktopInstall: XCTAssertEqual($0.expire, -1)
            case .mobileInstall: XCTAssertEqual($0.expire, -1)
            case .addPhone: XCTAssertEqual($0.expire, -1)
            }
        }
    }
}
