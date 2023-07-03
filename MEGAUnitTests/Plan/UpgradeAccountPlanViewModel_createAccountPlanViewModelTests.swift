import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class UpgradeAccountPlanViewModel_createAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private let proI_monthly = AccountPlanEntity(type: .proI, name: "Pro I", term: .monthly)
    private let proI_yearly = AccountPlanEntity(type: .proI, name: "Pro I", term: .yearly)
    private let proII_monthly = AccountPlanEntity(type: .proII, name: "Pro II", term: .monthly)
    private let proII_yearly = AccountPlanEntity(type: .proII, name: "Pro II", term: .yearly)
    private let proIII_monthly = AccountPlanEntity(type: .proII, name: "Pro III", term: .monthly)
    private let proIII_yearly = AccountPlanEntity(type: .proII, name: "Pro III", term: .yearly)
    
    func testCreateAccountPlanViewModel_withSelectedPlanType_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proIII_monthly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        sut.setSelectedPlan(proIII_monthly)
        
        let viewModel = sut.createAccountPlanViewModel(proIII_monthly)
        XCTAssertTrue(viewModel.isSelected)
        XCTAssertEqual(viewModel.plan, proIII_monthly)
        XCTAssertTrue(viewModel.isSelectionEnabled)
        XCTAssertEqual(viewModel.planTag, .none)
    }

    func testCreateAccountPlanViewModel_noSelectedPlan_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proII_yearly]
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
        let viewModel = sut.createAccountPlanViewModel(proII_yearly)
        XCTAssertFalse(viewModel.isSelected)
        XCTAssertEqual(viewModel.plan, proII_yearly)
        XCTAssertTrue(viewModel.isSelectionEnabled)
        XCTAssertEqual(viewModel.planTag, .none)
    }

    func testCreateAccountPlanViewModel_recurringPlanMonthly_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan Tag for recurring monthly plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        let monthlyPlanViewModel = sut.createAccountPlanViewModel(proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .currentPlan)

        let yearlyPlanViewModel = sut.createAccountPlanViewModel(proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .none)
    }

    func testCreateAccountPlanViewModel_recurringPlanYearly_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proI_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan Tag for recurring yearly plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        let monthlyPlanViewModel = sut.createAccountPlanViewModel(proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .none)

        let yearlyPlanViewModel = sut.createAccountPlanViewModel(proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .currentPlan)
    }

    func testCreateAccountPlanViewModel_oneTimePlanPurchase_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)

        let exp = expectation(description: "Setting Current plan Tag for one time purchase of plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)

        let monthlyPlanViewModel = sut.createAccountPlanViewModel(proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .currentPlan)

        let yearlyPlanViewModel = sut.createAccountPlanViewModel(proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .currentPlan)
    }
    
    func testCreateAccountPlanViewModel_withRecommendedPlanType_onRecommendedPlan_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .free)
        let planList = [proI_monthly, proI_yearly, proII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        let monthlyPlanViewModel = sut.createAccountPlanViewModel(proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .recommended)
        
        let yearlyPlanViewModel = sut.createAccountPlanViewModel(proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .recommended)
    }
    
    func testCreateAccountPlanViewModel_withRecommendedPlanType_onNotRecommendedPlan_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .free)
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
        
        let monthlyPlanViewModel = sut.createAccountPlanViewModel(proII_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, proII_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .none)
        
        let yearlyPlanViewModel = sut.createAccountPlanViewModel(proII_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, proII_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .none)
    }
    
    func testCreateAccountPlanViewModel_withNoRecommendedPlanType_shouldReturnViewModel() {
        let details = AccountDetailsEntity(proLevel: .proIII)
        let planList = [proIII_monthly, proIII_yearly]
        let mockUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        
        let exp = expectation(description: "Setting Current plan")
        let sut = UpgradeAccountPlanViewModel(accountDetails: details, purchaseUseCase: mockUseCase)
        sut.$currentPlan
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        wait(for: [exp], timeout: 0.5)
        
        let monthlyPlanViewModel = sut.createAccountPlanViewModel(proIII_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, proIII_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .none)
        
        let yearlyPlanViewModel = sut.createAccountPlanViewModel(proIII_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, proIII_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .none)
    }
}
