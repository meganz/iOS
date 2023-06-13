import MEGAData
import MEGADomain
import MEGASdk
import MEGASwift

final class UpgradeAccountPlanViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private var planList: [AccountPlanEntity] = []
    private var accountDetails: AccountDetailsEntity
    
    @Published var isDismiss = false
    @Published var selectedTermIndex = 1
    @Published private(set) var currentPlan: AccountPlanEntity?
    private var recommendedPlan: AccountPlanEntity?
    
    var isShowBuyButton = false
    @Published private(set) var selectedPlan: AccountPlanEntity? {
        didSet {
            isShowBuyButton = selectedPlan != nil
        }
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
            await setCurrentPlan(type: accountDetails.proLevel)
        }
    }
    
    @MainActor
    private func setCurrentPlan(type: AccountTypeEntity) {
        guard type != .free else {
            currentPlan = AccountPlanEntity(type: .free, name: AccountTypeEntity.free.toAccountTypeDisplayName())
            return
        }
        currentPlan = planList.first { plan in
            plan.type == type
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
        switch selectedTermIndex {
        case 0: return planList.filter { $0.term == .monthly }
        case 1: return planList.filter { $0.term == .yearly }
        default: return []
        }
    }
    
    func createAccountPlanViewModel(_ plan: AccountPlanEntity) -> AccountPlanViewModel {
        AccountPlanViewModel(
            plan: plan,
            planTag: planTag(plan),
            isSelected: isPlanSelected(plan),
            didTapPlan: {
                self.setSelectedPlan(plan)
            })
    }
    
    func setSelectedPlan(_ plan: AccountPlanEntity) {
        guard plan != currentPlan else { return }
        guard let selectedPlan else {
            selectedPlan = plan
            return
        }
        self.selectedPlan = selectedPlan != plan ? plan : nil
    }
    
    // MARK: - Private
    private func planTag(_ plan: AccountPlanEntity) -> AccountPlanTagEntity {
        if let currentPlan, plan == currentPlan { return .currentPlan }
        if let recommendedPlan, plan == recommendedPlan { return .recommended }
        return .none
    }
    
    private func isPlanSelected(_ plan: AccountPlanEntity) -> Bool {
        guard let selectedPlan else { return false }
        return selectedPlan == plan
    }
}
