import MEGADomain
import XCTest

final class AchievementTypeEntityMappingTests: XCTestCase {
    func testAchievementTypeEntity_withClassStorageTransformation_returnsExpectedResults() throws {
        let doubleThis: (Int) -> Int64 = { Int64($0  * 2) }
        let expectedResults: [AchievementTypeEntity: Int64] = [
            .welcome: Int64(1 * 2),
            .invite: Int64(3 * 2),
            .desktopInstall: Int64(4 * 2),
            .mobileInstall: Int64(5 * 2),
            .addPhone: Int64(9 * 2)
        ]
        AchievementTypeEntity.allCases.forEach {
            XCTAssertEqual($0.toAchievementDetails(classStorage: doubleThis).storage, expectedResults[$0])
        }
    }
    
    func testAchievementTypeEntity_withClassTransferTransformation_returnsExpectedResults() throws {
        let doubleThis: (Int) -> Int64 = { Int64($0  * 2) }
        let expectedResults: [AchievementTypeEntity: Int64] = [
            .welcome: Int64(1 * 2),
            .invite: Int64(3 * 2),
            .desktopInstall: Int64(4 * 2),
            .mobileInstall: Int64(5 * 2),
            .addPhone: Int64(9 * 2)
        ]
        AchievementTypeEntity.allCases.forEach {
            XCTAssertEqual($0.toAchievementDetails(classTransfer: doubleThis).transfer, expectedResults[$0])
        }
    }
    
    func testAchievementTypeEntity_withClassExpireTransformation_returnsExpectedResults() throws {
        let doubleThis: (Int) -> Int = { $0  * 2 }
        let expectedResults: [AchievementTypeEntity: Int] = [
            .welcome: 1 * 2,
            .invite: 3 * 2,
            .desktopInstall: 4 * 2,
            .mobileInstall: 5 * 2,
            .addPhone: 9 * 2
        ]
        AchievementTypeEntity.allCases.forEach {
            XCTAssertEqual($0.toAchievementDetails(classExpire: doubleThis).expire, expectedResults[$0])
        }
    }

}
