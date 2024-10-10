import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class UpgradeAccountPlanViewModel_createAccountPlanViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private let proI_monthly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .monthly)
    private let proI_yearly = PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly)
    private let proII_monthly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .monthly)
    private let proII_yearly = PlanEntity(type: .proII, name: "Pro II", subscriptionCycle: .yearly)
    private let proIII_monthly = PlanEntity(type: .proII, name: "Pro III", subscriptionCycle: .monthly)
    private let proIII_yearly = PlanEntity(type: .proII, name: "Pro III", subscriptionCycle: .yearly)
    
    func testCreateAccountPlanViewModel_withSelectedPlanType_shouldReturnViewModel() {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList = [proI_monthly, proIII_monthly]
        
        let exp = expectation(description: "Setting Current plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList = [proI_monthly, proII_yearly]

        let exp = expectation(description: "Setting Current plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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

    func disable_testCreateAccountPlanViewModel_recurringPlanMonthly_shouldReturnViewModel() {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList = [proI_monthly, proII_yearly]

        let exp = expectation(description: "Setting Current plan Tag for recurring monthly plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList = [proI_monthly, proI_yearly]

        let exp = expectation(description: "Setting Current plan Tag for recurring yearly plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList = [proI_monthly, proI_yearly, proII_yearly]

        let exp = expectation(description: "Setting Current plan Tag for one time purchase of plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList = [proI_monthly, proI_yearly, proII_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList = [proI_monthly, proI_yearly, proII_monthly, proII_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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
        let details = AccountDetailsEntity.build(proLevel: .proIII)
        let planList = [proIII_monthly, proIII_yearly]
        
        let exp = expectation(description: "Setting Current plan")
        let sut = makeSUT(accountDetails: details, planList: planList)
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
    
    // MARK: - Helper
    private func makeSUT(
        accountDetails: AccountDetailsEntity,
        currentAccountDetails: AccountDetailsEntity? = nil,
        planList: [PlanEntity] = [],
        viewType: UpgradeAccountPlanViewType = .upgrade
    ) -> UpgradeAccountPlanViewModel {
        let mockSubscriptionsUseCase = MockSubscriptionsUseCase()
        let mockPurchaseUseCase = MockAccountPlanPurchaseUseCase(accountPlanProducts: planList)
        let mockAccountUseCase = MockAccountUseCase(currentAccountDetails: currentAccountDetails)
        let sut = UpgradeAccountPlanViewModel(
            accountDetails: accountDetails,
            accountUseCase: mockAccountUseCase,
            purchaseUseCase: mockPurchaseUseCase,
            subscriptionsUseCase: mockSubscriptionsUseCase,
            viewType: viewType,
            router: MockUpgradeAccountPlanRouter()
        )
        trackForMemoryLeaks(on: mockSubscriptionsUseCase)
        trackForMemoryLeaks(on: mockPurchaseUseCase)
        trackForMemoryLeaks(on: sut)
        return sut
    }
}
