import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class UpgradeAccountPlanViewModel_createAccountPlanViewModelTests: XCTestCase {
    @MainActor func testCreateAccountPlanViewModel_withSelectedPlanType_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proIII_monthly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        sut.setSelectedPlan(.proIII_monthly)
        
        let viewModel = sut.createAccountPlanViewModel(.proIII_monthly)
        XCTAssertTrue(viewModel.isSelected)
        XCTAssertEqual(viewModel.plan, .proIII_monthly)
        XCTAssertTrue(viewModel.isSelectionEnabled)
        XCTAssertEqual(viewModel.planTag, .none)
    }

    @MainActor func testCreateAccountPlanViewModel_noSelectedPlan_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let sut = await makeSUT(accountDetails: details, planList: planList)

        sut.setSelectedPlan(.proI_monthly)
        
        let viewModel = sut.createAccountPlanViewModel(.proII_yearly)
        XCTAssertFalse(viewModel.isSelected)
        XCTAssertEqual(viewModel.plan, .proII_yearly)
        XCTAssertTrue(viewModel.isSelectionEnabled)
        XCTAssertEqual(viewModel.planTag, .none)
    }

    @MainActor func testCreateAccountPlanViewModel_recurringPlanMonthly_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proI_monthly, .proII_yearly]

        let sut = await makeSUT(accountDetails: details, planList: planList)

        let monthlyPlanViewModel = sut.createAccountPlanViewModel(.proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, .proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .currentPlan)

        let yearlyPlanViewModel = sut.createAccountPlanViewModel(.proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, .proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .none)
    }

    @MainActor func testCreateAccountPlanViewModel_recurringPlanYearly_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .yearly)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly]

        let sut = await makeSUT(accountDetails: details, planList: planList)

        let monthlyPlanViewModel = sut.createAccountPlanViewModel(.proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, .proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .none)

        let yearlyPlanViewModel = sut.createAccountPlanViewModel(.proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, .proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .currentPlan)
    }

    @MainActor func testCreateAccountPlanViewModel_oneTimePlanPurchase_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .proI, subscriptionCycle: .none)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_yearly]

        let sut = await makeSUT(accountDetails: details, planList: planList)

        let monthlyPlanViewModel = sut.createAccountPlanViewModel(.proI_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, .proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .currentPlan)

        let yearlyPlanViewModel = sut.createAccountPlanViewModel(.proI_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, .proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .currentPlan)
    }
    
    @MainActor func testCreateAccountPlanViewModel_withRecommendedPlanType_onRecommendedPlan_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        let monthlyPlanViewModel = sut.createAccountPlanViewModel(.proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, .proI_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .recommended)
        
        let yearlyPlanViewModel = sut.createAccountPlanViewModel(.proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, .proI_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .recommended)
    }
    
    @MainActor func testCreateAccountPlanViewModel_withRecommendedPlanType_onNotRecommendedPlan_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .free)
        let planList: [PlanEntity] = [.proI_monthly, .proI_yearly, .proII_monthly, .proII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        let monthlyPlanViewModel = sut.createAccountPlanViewModel(.proII_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, .proII_monthly)
        XCTAssertTrue(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .none)
        
        let yearlyPlanViewModel = sut.createAccountPlanViewModel(.proII_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, .proII_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .none)
    }
    
    @MainActor func testCreateAccountPlanViewModel_withNoRecommendedPlanType_shouldReturnViewModel() async {
        let details = AccountDetailsEntity.build(proLevel: .proIII, subscriptionCycle: .monthly)
        let planList: [PlanEntity] = [.proIII_monthly, .proIII_yearly]
        
        let sut = await makeSUT(accountDetails: details, planList: planList)
        
        let monthlyPlanViewModel = sut.createAccountPlanViewModel(.proIII_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelected)
        XCTAssertEqual(monthlyPlanViewModel.plan, .proIII_monthly)
        XCTAssertFalse(monthlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(monthlyPlanViewModel.planTag, .currentPlan)
        
        let yearlyPlanViewModel = sut.createAccountPlanViewModel(.proIII_yearly)
        XCTAssertFalse(yearlyPlanViewModel.isSelected)
        XCTAssertEqual(yearlyPlanViewModel.plan, .proIII_yearly)
        XCTAssertTrue(yearlyPlanViewModel.isSelectionEnabled)
        XCTAssertEqual(yearlyPlanViewModel.planTag, .none)
    }
    
    // MARK: - Helper
    @MainActor private func makeSUT(
        accountDetails: AccountDetailsEntity,
        currentAccountDetails: AccountDetailsEntity? = nil,
        planList: [PlanEntity] = [],
        viewType: UpgradeAccountPlanViewType = .upgrade
    ) async -> UpgradeAccountPlanViewModel {
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
        await sut.setupPlans()
        trackForMemoryLeaks(on: mockSubscriptionsUseCase)
        trackForMemoryLeaks(on: mockPurchaseUseCase)
        trackForMemoryLeaks(on: sut)
        return sut
    }
}
