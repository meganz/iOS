@testable import MEGA
import MEGADomain
import XCTest

final class UsageViewControllerTests: XCTestCase {

    func testShouldShowTransferQuota_freeAccount_shouldBeFalse() {
        let showTransferQuota = UsageViewController.shouldShowTransferQuota(accountType: .free)
        
        XCTAssertFalse(showTransferQuota)
    }
    
    func testShouldShowTransferQuota_notAFreeAccountType_shouldBeTrue() {
        AccountTypeEntity.allCases.enumerated()
          .filter { $1 != .free }
          .forEach {
            let result = UsageViewController.shouldShowTransferQuota(accountType: $1)

            XCTAssertTrue(result, "Expect to get true, got \(result) instead at index: \($0)")
          }
    }
}
