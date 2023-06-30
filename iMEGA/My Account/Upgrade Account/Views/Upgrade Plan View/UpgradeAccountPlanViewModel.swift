import MEGAData
import MEGADomain
import MEGASdk
import MEGASwift

final class UpgradeAccountPlanViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private var planList: [AccountPlanEntity] = []
    private var accountDetails: AccountDetailsEntity
    
    @Published var isRestoreAccountPlan = false
    @Published var isTermsAndPoliciesPresented = false
    @Published var isDismiss = false
    @Published private(set) var currentPlan: AccountPlanEntity?
    private var recommendedPlan: AccountPlanEntity?
    
    var isShowBuyButton = false
    @Published var selectedTermTab: AccountPlanTermEntity = .yearly {
        didSet { toggleBuyButton() }
    }
    @Published private(set) var selectedPlan: AccountPlanEntity? {
        didSet { toggleBuyButton() }
    }
    
    init(accountDetails: AccountDetailsEntity, purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol) {
        self.purchaseUseCase = purchaseUseCase
        self.accountDetails = accountDetails
        setupPlans()
    }
    
    // MARK: - Setup
    private func setupPlans() {
        Task {
            planList = await purchaseUseCase.accountPlanProducts()
            await setDefaultPlanTermTab()
            await setCurrentPlan(type: accountDetails.proLevel)
        }
    }
    
    private func toggleBuyButton() {
        guard let selectedPlan else {
            isShowBuyButton = false
            return
        }

        let isSelectedYearlyPlanOnYearlyTab = selectedTermTab == .monthly && selectedPlan.term == .monthly
        let isSelectedMonthlyPlanOnMonthlyTab = selectedTermTab == .yearly && selectedPlan.term == .yearly
        isShowBuyButton = isSelectedMonthlyPlanOnMonthlyTab || isSelectedYearlyPlanOnYearlyTab
    }
    
    @MainActor
    private func setDefaultPlanTermTab() {
        selectedTermTab = accountDetails.subscriptionCycle == .monthly ? .monthly : .yearly
    }

    @MainActor
    private func setCurrentPlan(type: AccountTypeEntity) {
        guard type != .free else {
            currentPlan = AccountPlanEntity(type: .free, name: AccountTypeEntity.free.toAccountTypeDisplayName())
            return
        }

        let cycle = accountDetails.subscriptionCycle
        currentPlan = planList.first { plan in
            guard cycle != .none else {
                return plan.type == type
            }
            
            let term = cycle == .monthly ? AccountPlanTermEntity.monthly : AccountPlanTermEntity.yearly
            return plan.type == type && plan.term == term
        }
        
    }

    // MARK: - Public
    var currentPlanName: String {
        currentPlan?.name ?? ""
    }
    
    var selectedPlanName: String {
        selectedPlan?.name ?? ""
    }
    
    var filteredPlanList: [AccountPlanEntity] {
        planList.filter { $0.term == selectedTermTab }
    }
    
    func createAccountPlanViewModel(_ plan: AccountPlanEntity) -> AccountPlanViewModel {
        AccountPlanViewModel(
            plan: plan,
            planTag: planTag(plan),
            isSelected: isPlanSelected(plan),
            isSelectionEnabled: isSelectionEnabled(forPlan: plan),
            didTapPlan: {
                self.setSelectedPlan(plan)
            })
    }
    
    func setSelectedPlan(_ plan: AccountPlanEntity) {
        guard isSelectionEnabled(forPlan: plan) else { return }
        guard let selectedPlan else {
            selectedPlan = plan
            return
        }
        self.selectedPlan = selectedPlan != plan ? plan : nil
    }
    
    // MARK: - Private
    private func planTag(_ plan: AccountPlanEntity) -> AccountPlanTagEntity {
        guard let currentPlan else { return .none }
        
        switch accountDetails.subscriptionCycle {
        case .none:
            if currentPlan.type == plan.type { return .currentPlan }
        default:
            if plan == currentPlan { return .currentPlan }
        }

        if let recommendedPlan, plan == recommendedPlan { return .recommended }
        return .none
    }
    
    private func isPlanSelected(_ plan: AccountPlanEntity) -> Bool {
        guard let selectedPlan else { return false }
        return selectedPlan == plan
    }
    
    private func isSelectionEnabled(forPlan plan: AccountPlanEntity) -> Bool {
        guard let currentPlan, accountDetails.subscriptionCycle != .none else {
            return true
        }
        return currentPlan != plan
    }
}
