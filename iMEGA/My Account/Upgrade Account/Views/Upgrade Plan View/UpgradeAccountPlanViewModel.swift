import Accounts
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASdk
import MEGASDKRepo
import MEGASwift
import MEGASwiftUI
import SwiftUI

enum UpgradeAccountPlanTarget {
    case buyPlan, restorePlan, termsAndPolicies
}

enum UpgradeAccountPlanViewType {
    case onboarding, upgrade
}

final class UpgradeAccountPlanViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private var abTestProvider: any ABTestProviderProtocol
    private let tracker: any AnalyticsTracking
    private let router: any UpgradeAccountPlanRouting
    private var planList: [AccountPlanEntity] = []
    private var accountDetails: AccountDetailsEntity
    private(set) var viewType: UpgradeAccountPlanViewType
    @Published var isExternalAdsActive: Bool = false
    
    private(set) var alertType: UpgradeAccountPlanAlertType?
    @Published var isAlertPresented = false {
        didSet {
            if !isAlertPresented { setAlertType(nil) }
        }
    }
    
    @Published var isShowSnackBar = false
    private(set) var snackBarType: PlanSelectionSnackBarType = .none
    private var showSnackBarSubscription: AnyCancellable?
    
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
    private(set) var cancelActivePlanAndBuyNewPlanTask: Task<Void, Never>?
    
    init(
        accountDetails: AccountDetailsEntity,
        accountUseCase: some AccountUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        viewType: UpgradeAccountPlanViewType,
        router: any UpgradeAccountPlanRouting
    ) {
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.accountDetails = accountDetails
        self.abTestProvider = abTestProvider
        self.tracker = tracker
        self.viewType = viewType
        self.router = router
        registerDelegates()
        setupPlans()
    }
    
    deinit {
        deRegisterDelegates()
        registerDelegateTask?.cancel()
        setUpPlanTask?.cancel()
        buyPlanTask?.cancel()
        cancelActivePlanAndBuyNewPlanTask?.cancel()
        registerDelegateTask = nil
        setUpPlanTask = nil
        buyPlanTask = nil
        cancelActivePlanAndBuyNewPlanTask = nil
    }
    
    // MARK: - Setup
    @MainActor
    func setUpExternalAds() async {
        let isAdsEnabled = await abTestProvider.abTestVariant(for: .ads) == .variantA
        let isExternalAdsEnabled = await abTestProvider.abTestVariant(for: .externalAds) == .variantA
        isExternalAdsActive = isAdsEnabled && isExternalAdsEnabled
    }
    
    private func registerDelegates() {
        guard registerDelegateTask == nil else { return }
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
                    tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseSucceededEvent())
                    postAccountDidPurchasedPlanNotification()
                    postRefreshAccountDetailsNotification()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                        guard let self else { return }
                        postDismissOnboardingProPlanDialog()
                        isDismiss = true
                    }
                case .failure(let error):
                    tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseFailedEvent())
                    guard error.toPurchaseErrorStatus() != .paymentCancelled else { return }
                    setAlertType(.purchase(.failed))
                }
            }
            .store(in: &subscriptions)
    }
    
    private func setupPlans() {
        setUpPlanTask = Task {
            planList = await purchaseUseCase.accountPlanProducts()
            
            if viewType == .upgrade {
                setRecommendedPlan(basedOnPlan: accountDetails.proLevel)
            } else {
                let lowestPlan = planList.sorted(by: { $0.price < $1.price }).first ?? AccountPlanEntity()
                setRecommendedPlan(basedOnPlan: lowestPlan.type)
            }
            
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
        
        guard !type.isLowerTierPlan else {
            currentPlan = AccountPlanEntity(type: type, name: type.toAccountTypeDisplayName())
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
                                   textColor: MEGAAppColor.Account.upgradeAccountPrimaryText.color,
                                   linkColor: MEGAAppColor.View.turquoise.color)
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
            router.showTermsAndPolicies()
        case .restorePlan:
            restorePurchase()
        case .buyPlan:
            buySelectedPlan()
        }
    }
    
    func cancelUpgradeButtonTapped() {
        tracker.trackAnalyticsEvent(with: CancelUpgradeMyAccountEvent())
        isDismiss = true
    }
    
    func onLoad() {
        tracker.trackAnalyticsEvent(with: UpgradeAccountPlanScreenEvent())
    }

    // MARK: - Private
    private func postRefreshAccountDetailsNotification() {
        NotificationCenter.default.post(name: .refreshAccountDetails, object: nil)
    }
    
    private func postAccountDidPurchasedPlanNotification() {
        NotificationCenter.default.post(name: .accountDidPurchasedPlan, object: nil)
    }
    
    private func postDismissOnboardingProPlanDialog() {
        NotificationCenter.default.post(name: .dismissOnboardingProPlanDialog, object: nil)
    }
    
    private func setRecommendedPlan(basedOnPlan plan: AccountTypeEntity) {
        switch plan {
        case .free, .lite, .starter, .basic, .essential:
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
    
    @MainActor
    private func startLoading() {
        isLoading = true
    }
    
    // MARK: Restore
    private func restorePurchase() {
        purchaseUseCase.restorePurchase()
    }
    
    // MARK: Buy plan
    var currentSelectedPlan: AccountPlanEntity? {
        guard let selectedPlanType,
              let selectedPlan = filteredPlanList.first(where: { $0.type == selectedPlanType }) else {
            return nil
        }
        return selectedPlan
    }
    
    private func trackEventBuyPlan(_ currentSelectedPlan: AccountPlanEntity) {
        switch currentSelectedPlan.type {
        case .proI:
            tracker.trackAnalyticsEvent(with: BuyProIEvent())
        case .proII:
            tracker.trackAnalyticsEvent(with: BuyProIIEvent())
        case .proIII:
            tracker.trackAnalyticsEvent(with: BuyProIIIEvent())
        case .lite:
            tracker.trackAnalyticsEvent(with: BuyProLiteEvent())
        default:
            break
        }
    }
    
    private func buySelectedPlan() {
        guard let currentSelectedPlan else { return }
        
        buyPlanTask = Task { [weak self] in
            guard let self else { return }
            MEGALogDebug("[Upgrade Account] Starting plan purchase.")
            
            do {
                try validateActiveSubscriptions()
                
                await startLoading()
                await purchaseUseCase.purchasePlan(currentSelectedPlan)
                trackEventBuyPlan(currentSelectedPlan)
            } catch {
                guard let error = error as? ActiveSubscriptionError else {
                    fatalError("[Upgrade Account] Error \(error) is not supported.")
                }
                
                await handleActiveSubscription(type: error)
            }
        }
    }
    
    func validateActiveSubscriptions() throws {
        guard accountDetails.proLevel != .free,
              accountDetails.subscriptionStatus == .valid,
              accountDetails.subscriptionMethodId != .itunes else { return }
        
        switch accountDetails.subscriptionMethodId {
        case .ECP, .sabadell, .stripe2:
            throw ActiveSubscriptionError.haveCancellablePlan
        default:
            throw ActiveSubscriptionError.haveNonCancellablePlan
        }
    }
    
    @MainActor
    func handleActiveSubscription(type: ActiveSubscriptionError) {
        guard type == .haveCancellablePlan else {
            setAlertType(.activeSubscription(type, primaryButtonAction: nil))
            return
        }
        
        setAlertType(.activeSubscription(type, primaryButtonAction: { [weak self] in
            guard let self else { return }
            cancelActivePlanAndBuyNewPlanTask = Task { [weak self] in
                guard let self else { return }
                await cancelActiveCancellableSubscription()
                buySelectedPlan()
            }
        }))
    }
    
    func cancelActiveCancellableSubscription() async {
        do {
            try await purchaseUseCase.cancelCreditCardSubscriptions(reason: nil)
            await refreshAccountDetails()
        } catch {
            MEGALogError("[Upgrade Account] Unable to cancel active subscription")
        }
    }
    
    // MARK: - Account details
    func refreshAccountDetails() async {
        do {
            accountDetails = try await accountUseCase.refreshCurrentAccountDetails()
        } catch {
            MEGALogError("Error loading account details. Error: \(error)")
        }
    }
}
