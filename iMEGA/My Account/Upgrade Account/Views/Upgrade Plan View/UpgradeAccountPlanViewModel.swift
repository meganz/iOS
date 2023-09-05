import Combine
import MEGADomain
import MEGAL10n
import MEGASdk
import MEGASDKRepo
import MEGASwift
import MEGASwiftUI
import SwiftUI

enum UpgradeAccountPlanTarget {
    case buyPlan, restorePlan, termsAndPolicies
}

final class UpgradeAccountPlanViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private var planList: [AccountPlanEntity] = []
    private var accountDetails: AccountDetailsEntity
    
    private(set) var alertType: UpgradeAccountPlanAlertType?
    @Published var isAlertPresented = false {
        didSet {
            if !isAlertPresented { setAlertType(nil) }
        }
    }
    
    @Published var isShowSnackBar = false
    private(set) var snackBarType: PlanSelectionSnackBarType = .none
    private var showSnackBarSubscription: AnyCancellable?
    
    @Published var isTermsAndPoliciesPresented = false
    @Published var isDismiss = false
    @Published var isLoading = false
    @Published private(set) var currentPlan: AccountPlanEntity?
    private(set) var recommendedPlanType: AccountTypeEntity?
    var isShowBuyButton = false
    
    @Published var selectedCycleTab: SubscriptionCycleEntity = .yearly {
        didSet { toggleBuyButton() }
    }
    @Published private(set) var selectedPlanType: AccountTypeEntity? {
        didSet { toggleBuyButton() }
    }
    
    private(set) var registerDelegateTask: Task<Void, Never>?
    private(set) var setUpPlanTask: Task<Void, Never>?
    private(set) var buyPlanTask: Task<Void, Never>?
    private(set) var restorePlanTask: Task<Void, Never>?
    
    init(accountDetails: AccountDetailsEntity, purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol) {
        self.purchaseUseCase = purchaseUseCase
        self.accountDetails = accountDetails
        registerDelegates()
        setupPlans()
    }
    
    deinit {
        deRegisterDelegates()
        registerDelegateTask?.cancel()
        setUpPlanTask?.cancel()
        buyPlanTask?.cancel()
        restorePlanTask?.cancel()
    }
    
    // MARK: - Setup
    private func registerDelegates() {
        registerDelegateTask = Task {
            await purchaseUseCase.registerRestoreDelegate()
            await purchaseUseCase.registerPurchaseDelegate()
            setupSubscriptions()
        }
    }
    
    private func deRegisterDelegates() {
        Task.detached { [weak self] in
            await self?.purchaseUseCase.deRegisterRestoreDelegate()
            await self?.purchaseUseCase.deRegisterPurchaseDelegate()
        }
    }
    
    private func setupSubscriptions() {
        purchaseUseCase.successfulRestorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                setAlertType(.restore(.success))
            }
            .store(in: &subscriptions)
        
        purchaseUseCase.incompleteRestorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                setAlertType(.restore(.incomplete))
            }
            .store(in: &subscriptions)
        
        purchaseUseCase.failedRestorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                setAlertType(.restore(.failed))
            }
            .store(in: &subscriptions)
        
        purchaseUseCase.purchasePlanResultPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                isLoading = false
                
                switch result {
                case .success:
                    postRefreshAccountDetailsNotification()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self else { return }
                        isDismiss = true
                    }
                case .failure(let error):
                    guard error.toPurchaseErrorStatus() != .paymentCancelled else { return }
                    setAlertType(.purchase(.failed))
                }
            }
            .store(in: &subscriptions)
    }
    
    private func setupPlans() {
        setUpPlanTask = Task {
            planList = await purchaseUseCase.accountPlanProducts()
            setRecommendedPlan()
            await setDefaultPlanCycleTab()
            await setCurrentPlan(type: accountDetails.proLevel)
        }
    }
    
    private func toggleBuyButton() {
        guard let currentSelectedPlan else {
            isShowBuyButton = false
            return
        }
        isShowBuyButton = isSelectionEnabled(forPlan: currentSelectedPlan)
    }
    
    @MainActor
    private func setDefaultPlanCycleTab() {
        selectedCycleTab = accountDetails.subscriptionCycle == .monthly ? .monthly : .yearly
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
            
            return plan.type == type && plan.subscriptionCycle == cycle
        }
    }

    // MARK: - Public
    var currentPlanName: String {
        currentPlan?.name ?? ""
    }
    
    var selectedPlanName: String {
        selectedPlanType?.toAccountTypeDisplayName() ?? ""
    }
    
    var filteredPlanList: [AccountPlanEntity] {
        planList.filter { $0.subscriptionCycle == selectedCycleTab }
    }
    
    var pricingPageFooterDetails: TextWithLinkDetails {
        let fullText = Strings.Localizable.UpgradeAccountPlan.Footer.Message.pricingPage
        let tappableText = fullText.subString(from: "[A]", to: "[/A]") ?? ""
        let fullTextWithoutFormatters = fullText
                                            .replacingOccurrences(of: "[A]", with: "")
                                            .replacingOccurrences(of: "[/A]", with: "")
        return TextWithLinkDetails(fullText: fullTextWithoutFormatters,
                                   tappableText: tappableText,
                                   linkString: "https://mega.nz/pro",
                                   textColor: Color(Colors.UpgradeAccount.primaryText.color),
                                   linkColor: Color(Colors.Views.turquoise.color))
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
        guard isSelectionEnabled(forPlan: plan) else {
            showSnackBar(for: .currentRecurringPlanSelected)
            return
        }
        selectedPlanType = plan.type
    }
    
    func setAlertType(_ type: UpgradeAccountPlanAlertType?) {
        alertType = type
        
        let shouldPresentAlert = type != nil
        guard shouldPresentAlert != isAlertPresented else { return }
        isAlertPresented = shouldPresentAlert
    }
    
    func showSnackBar(for type: PlanSelectionSnackBarType) {
        guard snackBarType != type || !isShowSnackBar else { return }
        snackBarType = type
        isShowSnackBar = true
    }
    
    func snackBarViewModel() -> SnackBarViewModel {
        let snackBar = SnackBar(message: snackBarType.title)
        let viewModel = SnackBarViewModel(snackBar: snackBar)

        showSnackBarSubscription = viewModel.$isShowSnackBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isShow in
                guard let self else { return }
                if isShow { snackBarType = .none }
                isShowSnackBar = isShow
            }
        
        return viewModel
    }
    
    func didTap(_ target: UpgradeAccountPlanTarget) {
        switch target {
        case .termsAndPolicies:
            isTermsAndPoliciesPresented = true
        case .restorePlan:
            restorePurchase()
        case .buyPlan:
            buySelectedPlan()
        }
    }

    // MARK: - Private
    private func postRefreshAccountDetailsNotification() {
        NotificationCenter.default.post(name: .refreshAccountDetails, object: nil)
    }
    
    private func setRecommendedPlan() {
        switch accountDetails.proLevel {
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
    
    private func planTag(_ plan: AccountPlanEntity) -> AccountPlanTagEntity {
        guard let currentPlan else { return .none }
        
        switch accountDetails.subscriptionCycle {
        case .none:
            if currentPlan.type == plan.type { return .currentPlan }
            if let recommendedPlanType, plan.type == recommendedPlanType { return .recommended }
        default:
            if plan == currentPlan { return .currentPlan }
            if let recommendedPlanType,
                plan.subscriptionCycle == selectedCycleTab,
                plan.type == recommendedPlanType {
                return .recommended
            }
        }
        
        return .none
    }
    
    private func isPlanSelected(_ plan: AccountPlanEntity) -> Bool {
        guard let selectedPlanType else { return false }
        return selectedPlanType == plan.type && isSelectionEnabled(forPlan: plan)
    }
    
    private func isSelectionEnabled(forPlan plan: AccountPlanEntity) -> Bool {
        guard let currentPlan, accountDetails.subscriptionCycle != .none else {
            return true
        }
        return currentPlan != plan
    }
    
    // MARK: Restore
    private func restorePurchase() {
        restorePlanTask = Task { [weak self] in
            guard let self else { return }
            await purchaseUseCase.restorePurchase()
        }
    }
    
    // MARK: Buy plan
    var currentSelectedPlan: AccountPlanEntity? {
        guard let selectedPlanType,
              let selectedPlan = filteredPlanList.first(where: { $0.type == selectedPlanType }) else {
            return nil
        }
        return selectedPlan
    }
    
    private func buySelectedPlan() {
        guard let currentSelectedPlan else { return }
        isLoading = true
        buyPlanTask = Task { [weak self] in
            guard let self else { return }
            await purchaseUseCase.purchasePlan(currentSelectedPlan)
        }
    }
}
