import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class AccountHallViewModelTests: XCTestCase {
    
    func testAction_startOrJoinCallCleanUp_callCleanUp() {
        let accountHallUseCase = MockAccountHallUseCase()
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase)
        
        test(viewModel: sut, actions: [AccountHallAction.onViewAppear], expectedCommands: [AccountHallViewModel.Command.reload])
    }
    
    func testAction_didTapUpgradeButton_showUpgradeView() {
        let accountHallUseCase = MockAccountHallUseCase()
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase)
        
        test(viewModel: sut, actions: [AccountHallAction.didTapUpgradeButton], expectedCommands: [])
    }
}
