import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class UpgradeAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private let freePlan = AccountPlanEntity(type: .free, name: "Free")
    private let proLite = AccountPlanEntity(type: .lite, name: "Pro Lite", term: .monthly)
    private let proI = AccountPlanEntity(type: .proI, name: "Pro I", term: .monthly)
    private let proII = AccountPlanEntity(type: .proII, name: "Pro II", term: .yearly)
    private let proIII = AccountPlanEntity(type: .proIII, name: "Pro III", term: .yearly)
    
    func testCurrentPlanValue_freePlan_shouldBeFreePlan() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, freePlan)
    }

    func testCurrentPlanValue_freePlan_shouldNotBeNil() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, nil)
    }
    
    func testCurrentPlanName_shouldMatchCurrentPlanName() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlanName, "Free")
    }
    
    func testCurrentPlanValue_shouldMatchCurrentPlan() {
        let details = AccountDetailsEntity(proLevel: .lite)
        let planList = [proLite, proI]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, proLite)
    }
    
    func testCurrentPlanValue_notMatched_shouldBeFailed() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, proLite)
        XCTAssertNotEqual(sut.currentPlan, proI)
    }
    
    func testSelectedPlanName_shouldMatchSelectedPlanName() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI, proII, proIII]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI)
        XCTAssertEqual(sut.selectedPlanName, proI.name)
    }
    
    func testSelectedPlan_shouldMatchSelectedPlan() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI, proII, proIII]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI)
        XCTAssertEqual(sut.selectedPlan, proI)
    }
    
    func testSelectedPlan_willSelectCurrentPlan_shouldNotSetSelectedPlan() {
        let details = AccountDetailsEntity(proLevel: .proI)
        let planList = [proLite, proI, proII, proIII]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI)
        XCTAssertNotEqual(sut.selectedPlan, proI)
    }
    
    func testSelectedTermIndex_default_shouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        XCTAssertEqual(sut.selectedTermIndex, 1)
    }
    
    func testCreateAccountPlanViewModel_withSelectedPlan_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proLite)
        let viewModel = sut.createAccountPlanViewModel(proLite)
        
        XCTAssertTrue(viewModel.isSelected)
        XCTAssertEqual(viewModel.plan, proLite)
        XCTAssertFalse(viewModel.isCurrenPlan)
        XCTAssertEqual(viewModel.planTag, .none)
    }
    
    func testCreateAccountPlanViewModel_notSelectedPlan_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI)
        let viewModel = sut.createAccountPlanViewModel(proLite)
        
        XCTAssertFalse(viewModel.isSelected)
        XCTAssertEqual(viewModel.plan, proLite)
        XCTAssertFalse(viewModel.isCurrenPlan)
        XCTAssertEqual(viewModel.planTag, .none)
    }
    
    func testIsShowBuyButton_withSelectedPlan_shouldBeTrue() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI)
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    func testIsShowBuyButton_noSelectedPlan_shouldBeFalse() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI, proII, proIII]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Set selected plan term")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedTermIndex
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.selectedTermIndex = 0
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.filteredPlanList, [proLite, proI])
    }
    
    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proLite, proI, proII, proIII]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Set selected plan term")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedTermIndex
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.selectedTermIndex = 1
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.filteredPlanList, [proII, proIII])
    }
}
