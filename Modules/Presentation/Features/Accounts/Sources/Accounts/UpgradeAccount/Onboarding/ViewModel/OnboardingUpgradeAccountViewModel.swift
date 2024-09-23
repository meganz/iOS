import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import Settings

enum OnboardingUpgradeAccountEvent {
    case selectedPlan(plan: AccountTypeEntity)
    case proIIIPlanCardDisplayed
}

public final class OnboardingUpgradeAccountViewModel: ObservableObject {
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private var subscriptions: Set<AnyCancellable> = []
    private let router: OnboardingUpgradeAccountRouting
    private var proIIIPlanCardShownEventTracked: Bool = false
    let isAdsEnabled: Bool
    private let baseStorage: Int
    
    @Published private(set) var shouldDismiss: Bool = false
    @Published private(set) var lowestProPlan: PlanEntity = PlanEntity()
    
    // Variant A only
    private let viewProPlanAction: () -> Void
    let notificationCenter: NotificationCenter
    
    // Variant B only
    @Published var selectedCycleTab: SubscriptionCycleEntity = .yearly
    @Published private(set) var selectedPlanType: AccountTypeEntity?
    @Published var isTermsAndPoliciesPresented = false
    private var planList: [PlanEntity] = []
    private(set) var recommendedPlanType: AccountTypeEntity?
    
    private(set) var purchasePlanTask: Task<Void, Never>?
    private(set) var alertType: UpgradeAccountPlanAlertType?
    
    @Published var isLoading = false
    @Published var isAlertPresented = false {
        didSet {
            if !isAlertPresented { setAlertType(nil) }
        }
    }
    
    public init(
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        tracker: some AnalyticsTracking,
        isAdsEnabled: Bool,
        baseStorage: Int,
        viewProPlanAction: @escaping () -> Void,
        router: OnboardingUpgradeAccountRouting,
        notificationCenter: NotificationCenter = NotificationCenter.default
    ) {
        self.purchaseUseCase = purchaseUseCase
        self.accountUseCase = accountUseCase
        self.tracker = tracker
        self.isAdsEnabled = isAdsEnabled
        self.baseStorage = baseStorage
        self.viewProPlanAction = viewProPlanAction
        self.router = router
        self.notificationCenter = notificationCenter
    }
    
    public func cancelPurchaseTask() {
        purchasePlanTask?.cancel()
    }
    
    @MainActor
    public func startPurchaseUpdatesMonitoring() async throws {
        for await result in purchaseUseCase.purchasePlanResultUpdates {
            try Task.checkCancellation()
            
            switch result {
            case .success:
                postAccountDidPurchasedPlanNotification()
                try await Task.sleep(nanoseconds: 1_000_000_000)

                setLoading(false)
                shouldDismiss = true
            case .failure(let error):
                setLoading(false)
                guard error.toPurchaseErrorStatus() != .paymentCancelled else { return }
                setAlertType(.purchase(.failed))
            }
        }
    }
    
    @MainActor
    public func startRestoreUpdatesMonitoring() async throws {
        for await result in purchaseUseCase.restorePurchaseUpdates {
            try Task.checkCancellation()
            
            switch result {
            case .success: setAlertType(.restore(.success))
            case .incomplete: setAlertType(.restore(.incomplete))
            case .failed: setAlertType(.restore(.failed))
            }
        }
    }
    
    private func postAccountDidPurchasedPlanNotification() {
        NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
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
    
    func setAlertType(_ type: UpgradeAccountPlanAlertType?) {
        alertType = type
        
        let shouldPresentAlert = type != nil
        guard shouldPresentAlert != isAlertPresented else { return }
        isAlertPresented = shouldPresentAlert
    }
   
    // MARK: - Variant A with View Pro Plans
    func setUpSubscription() {
        notificationCenter
            .publisher(for: .dismissOnboardingProPlanDialog)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                shouldDismiss = true
            }
            .store(in: &subscriptions)
    }
    
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
    
    private lazy var freeAccountPlan = PlanEntity(
        type: .free,
        name: Strings.Localizable.Free.Plan.name,
        subscriptionCycle: .none,
        storage: Strings.Localizable.Storage.Limit.capacity(baseStorage),
        transfer: Strings.Localizable.Account.TransferQuota.FreePlan.limited,
        formattedPrice: Strings.Localizable.Free.Plan.Price.description
    )
    
    var selectedPlanName: String {
        selectedPlanType?.toAccountTypeDisplayName() ?? ""
    }
    
    var filteredPlanList: [PlanEntity] {
        planList.filter { $0.subscriptionCycle == selectedCycleTab || $0.subscriptionCycle == .none }
    }
    
    var currentSelectedPlan: PlanEntity? {
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
    
    func createAccountPlanViewModel(_ plan: PlanEntity) -> AccountPlanViewModel {
        AccountPlanViewModel(
            plan: plan,
            planTag: planTag(plan),
            isSelected: isPlanSelected(plan),
            isSelectionEnabled: true,
            didTapPlan: {
                self.setSelectedPlan(plan)
            })
    }
    
    private func planTag(_ plan: PlanEntity) -> AccountPlanTagEntity {
        guard let recommendedPlanType,
              plan.subscriptionCycle == selectedCycleTab,
              plan.type == recommendedPlanType else {
            return .none
        }
        
        return .recommended
    }
    
    private func isPlanSelected(_ plan: PlanEntity) -> Bool {
        guard let selectedPlanType else { return false }
        return selectedPlanType == plan.type
    }
    
    func setSelectedPlan(_ plan: PlanEntity) {
        selectedPlanType = plan.type
    }
    
    // MARK: - Analytics events tracking
    
    private func trackEvent(_ event: OnboardingUpgradeAccountEvent) {
        switch event {
        case .selectedPlan(let plan):
            switch plan {
            case .free: tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantBFreePlanContinueButtonPressedEvent())
            case .proI: tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantBProIPlanContinueButtonPressedEvent())
            case .proII: tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantBProIIPlanContinueButtonPressedEvent())
            case .proIII: tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantBProIIIPlanContinueButtonPressedEvent())
            case .lite: tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantBProLitePlanContinueButtonPressedEvent())
            default: break
            }
        case .proIIIPlanCardDisplayed:
            guard !proIIIPlanCardShownEventTracked else { return }
            tracker.trackAnalyticsEvent(with: OnboardingUpsellingDialogVariantBProPlanIIIDisplayedEvent())
            proIIIPlanCardShownEventTracked = true
        }
    }
    
    func trackSelectedPlanEvent() {
        guard let selectedPlanType else { return }
        trackEvent(.selectedPlan(plan: selectedPlanType))
    }
    
    func trackProIIICardDisplayedEvent() {
        trackEvent(.proIIIPlanCardDisplayed)
    }
    
    // MARK: - Variant B functionalities
    func restorePurchase() {
        purchaseUseCase.restorePurchase()
    }
    
    func showTermsAndPolicies() {
        router.showTermsAndPolicies()
    }
    
    func purchaseSelectedPlan() {
        trackSelectedPlanEvent()
        guard let selectedPlan = filteredPlanList.first(where: { $0.type == selectedPlanType }) else { return }
        
        guard selectedPlan.type != .free else {
            shouldDismiss = true
            return
        }
        
        purchasePlanTask = Task { [weak self] in
            guard let self else { return }
            
            await setLoading(true)
            await purchaseUseCase.purchasePlan(selectedPlan)
        }
    }
    
    @MainActor
    private func setLoading(_ shouldLoad: Bool) {
        isLoading = shouldLoad
    }
    
    // MARK: - Helper
    private func lowestPlan(planList: [PlanEntity]) -> PlanEntity {
        return planList.sorted(by: { $0.price < $1.price }).first ?? PlanEntity()
    }
}
