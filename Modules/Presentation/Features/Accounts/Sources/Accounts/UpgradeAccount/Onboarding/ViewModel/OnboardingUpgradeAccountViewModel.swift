import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation

public final class OnboardingUpgradeAccountViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private var subscriptions: Set<AnyCancellable> = []
    
    @Published private(set) var shouldDismiss: Bool = false
    @Published private(set) var lowestProPlan: AccountPlanEntity = AccountPlanEntity()
    
    // Variant A only
    private let viewProPlanAction: () -> Void
    
    // Variant B only
    @Published var selectedCycleTab: SubscriptionCycleEntity = .yearly
    @Published private(set) var selectedPlanType: AccountTypeEntity?
    private var planList: [AccountPlanEntity] = []
    private(set) var recommendedPlanType: AccountTypeEntity?
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        tracker: some AnalyticsTracking,
        viewProPlanAction: @escaping () -> Void
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.tracker = tracker
        self.viewProPlanAction = viewProPlanAction
        
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        NotificationCenter.default
            .publisher(for: .dismissOnboardingProPlanDialog)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                shouldDismiss = true
            }
            .store(in: &subscriptions)
    }
    
    public var storageContentMessage: String {
        // Extract the memory and unit from the formatted storage string
        let storageComponents = lowestProPlan.storage.components(separatedBy: " ")
        guard storageComponents.count == 2 else { return ""}
        
        let message = Strings.Localizable.Onboarding.UpgradeAccount.Content.GenerousStorage.message
            .replacingOccurrences(of: "[A]", with: storageComponents[0]) // Storage limit
            .replacingOccurrences(of: "[B]", with: storageComponents[1]) // Storage unit
        return message
    }
   
    // MARK: - Variant A with View Pro Plans
    
    @MainActor
    public func setUpLowestProPlan() async {
        let planList = await self.purchaseUseCase.accountPlanProducts()
        lowestProPlan = lowestPlan(planList: planList)
    }
    
    func showProPlanView() {
        tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantAViewProPlansButtonEvent())
        
        viewProPlanAction()
    }
    
    // MARK: - Variant B with list of free and all Pro Plans
    
    @MainActor
    func setupPlans() async {
        planList = await purchaseUseCase.accountPlanProducts()
        
        // Set lowest pro plan
        lowestProPlan = lowestPlan(planList: planList)
        
        // Add free account on plan selection list
        planList.insert(freeAccountPlan, at: 0)
        
        // Set default recommended and selected plan
        setDefaultRecommendedSelectedPlan()
    }
    
    private let freeAccountPlan = AccountPlanEntity(
        type: .free,
        name: "Free",
        subscriptionCycle: .none,
        storage: "20 GB",
        transfer: "Limited",
        formattedPrice: "Free"
    )
    
    var selectedPlanName: String {
        selectedPlanType?.toAccountTypeDisplayName() ?? ""
    }
    
    var filteredPlanList: [AccountPlanEntity] {
        planList.filter { $0.subscriptionCycle == selectedCycleTab || $0.subscriptionCycle == .none }
    }
    
    var currentSelectedPlan: AccountPlanEntity? {
        guard let selectedPlanType,
              let selectedPlan = filteredPlanList.first(where: { $0.type == selectedPlanType }) else {
            return nil
        }
        return selectedPlan
    }
    
    private func setDefaultRecommendedSelectedPlan() {
        switch lowestProPlan.type {
        case .free, .lite:
            recommendedPlanType = .proI
        case .proI:
            recommendedPlanType = .proII
        case .proII:
            recommendedPlanType = .proIII
        default:
            return
        }
        selectedPlanType = recommendedPlanType
    }
    
    func createAccountPlanViewModel(_ plan: AccountPlanEntity) -> AccountPlanViewModel {
        AccountPlanViewModel(
            plan: plan,
            planTag: planTag(plan),
            isSelected: isPlanSelected(plan),
            isSelectionEnabled: true,
            didTapPlan: {
                self.setSelectedPlan(plan)
            })
    }
    
    private func planTag(_ plan: AccountPlanEntity) -> AccountPlanTagEntity {
        guard let recommendedPlanType,
              plan.subscriptionCycle == selectedCycleTab,
              plan.type == recommendedPlanType else {
            return .none
        }
        
        return .recommended
    }
    
    private func isPlanSelected(_ plan: AccountPlanEntity) -> Bool {
        guard let selectedPlanType else { return false }
        return selectedPlanType == plan.type
    }
    
    func setSelectedPlan(_ plan: AccountPlanEntity) {
        selectedPlanType = plan.type
    }
    
    // MARK: - Helper
    private func lowestPlan(planList: [AccountPlanEntity]) -> AccountPlanEntity {
        return planList.sorted(by: { $0.price < $1.price }).first ?? AccountPlanEntity()
    }
}
