@testable import MEGA
import MEGADomain
import XCTest

final class AccountPlanViewModelTests: XCTestCase {

    func testIsCurrentPlan_currentPlan_shouldBeTrue() {
        let sut = AccountPlanViewModel(plan: AccountPlanEntity(),
                                       planTag: .currentPlan,
                                       isSelected: false,
                                       didTapPlan: {})
        XCTAssertTrue(sut.isCurrenPlan)
    }
    
    func testIsCurrentPlan_recommended_shouldBeFalse() {
        let sut = AccountPlanViewModel(plan: AccountPlanEntity(),
                                       planTag: .recommended,
                                       isSelected: false,
                                       didTapPlan: {})
        XCTAssertFalse(sut.isCurrenPlan)
    }
    
    func testIsCurrentPlan_none_shouldBeFalse() {
        let sut = AccountPlanViewModel(plan: AccountPlanEntity(),
                                       planTag: .none,
                                       isSelected: false,
                                       didTapPlan: {})
        XCTAssertFalse(sut.isCurrenPlan)
    }
    
    func testIsCurrentPlan_notIndicated_shouldBeFalse() {
        let sut = AccountPlanViewModel(plan: AccountPlanEntity(),
                                       isSelected: false,
                                       didTapPlan: {})
        XCTAssertFalse(sut.isCurrenPlan)
    }
}
