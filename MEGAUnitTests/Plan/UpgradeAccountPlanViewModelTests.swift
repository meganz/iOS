import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class UpgradeAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private let freePlan = AccountPlanEntity(type: .free, name: "Free")
    private let proI_monthly = AccountPlanEntity(type: .proI, name: "Pro I", term: .monthly)
    private let proI_yearly = AccountPlanEntity(type: .proI, name: "Pro I", term: .yearly)
    private let proII_monthly = AccountPlanEntity(type: .proII, name: "Pro II", term: .monthly)
    private let proII_yearly = AccountPlanEntity(type: .proII, name: "Pro II", term: .yearly)
    
    func testCurrentPlanValue_freePlan_shouldBeFreePlan() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
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
        let planList = [proI_monthly, proI_yearly]
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
        let planList = [proI_monthly, proI_yearly]
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
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.currentPlan, proI_monthly)
    }
    
    func testCurrentPlanValue_notMatched_shouldBeFailed() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNotEqual(sut.currentPlan, proI_yearly)
        XCTAssertNotEqual(sut.currentPlan, proI_monthly)
    }
    
    func testSelectedPlanName_shouldMatchSelectedPlanName() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI_monthly)
        XCTAssertEqual(sut.selectedPlanName, proI_monthly.name)
    }
    
    func testSelectedPlan_freeAccount_shouldMatchSelectedPlan() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proI_monthly)
        XCTAssertEqual(sut.selectedPlan, proI_monthly)
    }

    func testSelectedPlan_recurringPlanAccount_selectCurrentPlan_shouldNotSelectPlan() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proI_monthly)
        XCTAssertNotEqual(sut.selectedPlan, proI_monthly)
    }

    func testSelectedTermTab_freeAccount_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()

        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        XCTAssertEqual(sut.selectedTermTab, .yearly)
    }

    func testSelectedTermTab_oneTimePurchaseMonthly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedTermTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedTermTab, .yearly)
    }

    func testSelectedTermTab_oneTimePurchaseYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedTermTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedTermTab, .yearly)
    }

    func testSelectedTermTab_recurringPlanYearly_defaultShouldBeYearly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedTermTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        XCTAssertEqual(sut.selectedTermTab, .yearly)
    }

    func testSelectedTermTab_recurringPlanMonthly_defaultShouldBeMonthly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Plan Term Tab")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$selectedTermTab
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.selectedTermTab, .monthly)
    }

    func testIsShowBuyButton_freeAccount_shouldBeTrue() {
        let details = AccountDetailsEntity(proLevel: .free, subscriptionCycle: .none)
        let planList = [proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proII_yearly)
        XCTAssertTrue(sut.isShowBuyButton)
    }

    func testIsShowBuyButton_selectedPlanTerm_equalToCurrentTermTab_shouldBeTrue() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proII_monthly)
        XCTAssertTrue(sut.isShowBuyButton)
    }

    func testIsShowBuyButton_selectedPlanTerm_notEqualToCurrentTermTab_shouldBeFalse() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.setSelectedPlan(proII_monthly)
        XCTAssertFalse(sut.isShowBuyButton)
    }

    func testIsShowBuyButton_noSelectedPlan_shouldBeFalse() {
        let details = AccountDetailsEntity(proLevel: .free)
        let mockUseCase = MockAccountPlanPurchaseUseCase()
        
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        XCTAssertFalse(sut.isShowBuyButton)
    }
    
    func testFilteredPlanList_monthly_shouldReturnMonthlyPlans() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Set selected plan term")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        sut.selectedTermTab = .monthly
        XCTAssertEqual(sut.filteredPlanList, [proI_monthly, proII_monthly])
    }
    
    func testFilteredPlanList_yearly_shouldReturnYearlyPlans() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proII_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Set selected plan term")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.selectedTermTab = .yearly
        XCTAssertEqual(sut.filteredPlanList, [proI_yearly, proII_yearly])
    }
}
