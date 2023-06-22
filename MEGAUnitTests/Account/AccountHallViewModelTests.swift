@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class AccountHallViewModelTests: XCTestCase {
    var accountHallUseCase: MockAccountHallUseCase!
    var purchaseUseCase: MockAccountPlanPurchaseUseCase!
    
    override func setUp() {
        super.setUp()
        accountHallUseCase = MockAccountHallUseCase()
        purchaseUseCase = MockAccountPlanPurchaseUseCase()
    }

    func testAction_onViewAppear() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase)
        test(viewModel: sut,
             actions: [AccountHallAction.reloadUI],
             expectedCommands: [.reloadUIContent])
    }
    
    func testAction_loadPlanList() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase)
        
        test(viewModel: sut,
             actions: [AccountHallAction.load(.planList)],
             expectedCommands: [.configPlanDisplay])
    }
    
    func testAction_loadAccountDetails() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase)
        
        test(viewModel: sut,
             actions: [AccountHallAction.load(.accountDetails)],
             expectedCommands: [.configPlanDisplay])
    }
    
    func testAction_loadContentCounts() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase)
        
        test(viewModel: sut,
             actions: [AccountHallAction.load(.contentCounts)],
             expectedCommands: [.reloadCounts])
    }
    
    func testAction_addSubscriptions() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase)
        
        test(viewModel: sut,
             actions: [AccountHallAction.addSubscriptions],
             expectedCommands: [])
    }
    
    func testAction_removeSubscriptions() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase)
        
        test(viewModel: sut,
             actions: [AccountHallAction.removeSubscriptions],
             expectedCommands: [])
    }

    func testIsMasterBusinessAccount_shouldBeTrue() {
        let sut = AccountHallViewModel(accountHallUsecase: MockAccountHallUseCase(isMasterBusinessAccount: true),
                                       purchaseUseCase: purchaseUseCase)
        
        XCTAssertTrue(sut.isMasterBusinessAccount)
    }
    
    func testIsMasterBusinessAccount_shouldBeFalse() {
        let sut = AccountHallViewModel(accountHallUsecase: MockAccountHallUseCase(isMasterBusinessAccount: false),
                                       purchaseUseCase: purchaseUseCase)
        
        XCTAssertFalse(sut.isMasterBusinessAccount)
    }
    
    func testAction_didTapUpgradeButton_showUpgradeView() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase)
        
        test(viewModel: sut, actions: [AccountHallAction.didTapUpgradeButton], expectedCommands: [])
    }
    
    func testIsFeatureFlagEnabled_onNewUpgradeAccountPlanEnabled_shouldBeEnabled() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase, featureFlagProvider: MockFeatureFlagProvider(list: [.newUpgradeAccountPlanUI: true]))
        XCTAssertTrue(sut.isNewUpgradeAccountPlanEnabled())
    }

    func testIsFeatureFlagEnabled_onNewUpgradeAccountPlanDisabled_shouldBeTurnedOff() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase, featureFlagProvider: MockFeatureFlagProvider(list: [.newUpgradeAccountPlanUI: false]))
        XCTAssertFalse(sut.isNewUpgradeAccountPlanEnabled())
    }
    
    func testIsFeatureFlagEnabled_onDeviceCenterUIEnabled_shouldBeEnabled() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase, featureFlagProvider: MockFeatureFlagProvider(list: [.deviceCenter: true]))
        XCTAssertTrue(sut.isDeviceCenterEnabled())
    }

    func testIsFeatureFlagEnabled_onDeviceCenterUIDisabled_shouldBeTurnedOff() {
        let sut = AccountHallViewModel(accountHallUsecase: accountHallUseCase, purchaseUseCase: purchaseUseCase, featureFlagProvider: MockFeatureFlagProvider(list: [.deviceCenter: false]))
        XCTAssertFalse(sut.isDeviceCenterEnabled())
    }
}
