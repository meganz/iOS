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
    private let proIII_monthly = AccountPlanEntity(type: .proIII, name: "Pro III", term: .monthly)
    
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
    
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanFree_shouldBeProI() {
        let details = AccountDetailsEntity(proLevel: .free)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }

    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanLite_shouldBeProI() {
        let details = AccountDetailsEntity(proLevel: .lite)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proI)
        XCTAssertEqual(sut.selectedPlanType, .proI)
    }
    
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProI_shouldBeProII() {
        let details = AccountDetailsEntity(proLevel: .proI)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proII)
        XCTAssertEqual(sut.selectedPlanType, .proII)
    }
    
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProII_shouldBeProIII() {
        let details = AccountDetailsEntity(proLevel: .proII)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(sut.recommendedPlanType, .proIII)
        XCTAssertEqual(sut.selectedPlanType, .proIII)
    }
    
    func testRecommendedPlanTypeAndDefaultSelectedPlanType_withCurrentPlanProIII_shouldHaveNoRecommendedPlanType() {
        let details = AccountDetailsEntity(proLevel: .proIII)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details,
                                              purchaseUseCase: MockAccountPlanPurchaseUseCase())
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertNil(sut.recommendedPlanType)
        XCTAssertNil(sut.selectedPlanType)
    }
    
    func testSelectedPlanTypeName_shouldMatchSelectedPlanName() {
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
    
    func testSelectedPlanType_freeAccount_shouldMatchSelectedPlanType() {
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
        XCTAssertEqual(sut.selectedPlanType, proI_monthly.type)
    }

    func testSelectedPlanType_recurringPlanAccount_selectCurrentPlan_shouldNotSelectPlanType() {
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
        XCTAssertNotEqual(sut.selectedPlanType, proI_monthly.type)
    }
    
    func testSelectedPlanType_recurringPlanAccount_selectSameCurrentPlanOnYearly_shouldNotHaveSelectedPlanOnMonthly() {
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

        sut.selectedTermTab = .yearly
        sut.setSelectedPlan(proI_yearly)
        XCTAssertEqual(sut.selectedPlanType, proI_yearly.type)
        
        sut.selectedTermTab = .monthly
        XCTAssertNil(sut.selectedPlanType)
    }
    
    func testSelectedPlanType_recurringPlanAccount_selectSameCurrentPlanOnMonthly_shouldNotHaveSelectedPlanOnYearly() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
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

        sut.selectedTermTab = .monthly
        sut.setSelectedPlan(proI_monthly)
        XCTAssertEqual(sut.selectedPlanType, proI_monthly.type)
        
        sut.selectedTermTab = .yearly
        XCTAssertNil(sut.selectedPlanType)
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

    func testIsShowBuyButton_selectedPlanTypeOnMonthly_thenSwitchedToYearlyTab_shouldBeTrue() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
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
        sut.selectedTermTab = .yearly
        XCTAssertTrue(sut.isShowBuyButton)
    }
    
    func testIsShowBuyButton_selectedPlanTypeOnYearly_thenSwitchedToMonthlyTab_shouldBeTrue() {
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

        sut.setSelectedPlan(proII_yearly)
        sut.selectedTermTab = .monthly
        XCTAssertTrue(sut.isShowBuyButton)
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
