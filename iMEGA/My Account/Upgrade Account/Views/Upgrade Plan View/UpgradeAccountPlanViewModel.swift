import MEGAData
import MEGADomain
import MEGASdk
import MEGASwift

final class UpgradeAccountPlanViewModel: ObservableObject {
    private let purchaseUseCase: AccountPlanPurchaseUseCaseProtocol
    private var planList: [AccountPlanEntity] = []
    private var accountDetails: AccountDetailsEntity
    
    @Published var isDismiss = false
    @Published var selectedTermIndex = 0
    @Published private(set) var currentPlan: AccountPlanEntity?

    var isShowBuyButton = false
    @Published private(set) var selectedPlan: AccountPlanEntity? {
        didSet {
            isShowBuyButton = selectedPlan != nil
        }
    }
    
    init(accountDetails: AccountDetailsEntity, purchaseUseCase: AccountPlanPurchaseUseCaseProtocol) {
        self.purchaseUseCase = purchaseUseCase
        self.accountDetails = accountDetails
        setupPlans()
    }
    
    //MARK: - Setup
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

    //MARK: - Public
    var currentPlanName: String {
        currentPlan?.name ?? ""
    }
    
    var selectedPlanName: String {
        selectedPlan?.name ?? ""
    }
}
