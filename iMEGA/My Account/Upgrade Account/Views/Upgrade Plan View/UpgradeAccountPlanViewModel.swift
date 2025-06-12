import Accounts
import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASdk
import MEGAStoreKit
import MEGASwift
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

enum UpgradeAccountPlanTarget {
    case buyPlan, restorePlan, termsAndPolicies, buyExternally, buyInApp
}

enum UpgradeAccountPlanViewType {
    case onboarding, upgrade
}

@MainActor
final class UpgradeAccountPlanViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let subscriptionsUseCase: any SubscriptionsUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private let localFeatureFlagProvider: any FeatureFlagProviderProtocol
    private let externalPurchaseUseCase: any ExternalPurchaseUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let router: any UpgradeAccountPlanRouting
    private let appVersion: String

    private let canOpenURL: @Sendable (URL) async -> Bool
    private let openURL: @Sendable (URL) async -> Void

    private var planList: [PlanEntity] = []
    private var accountDetails: AccountDetailsEntity
    private(set) var viewType: UpgradeAccountPlanViewType
    let isExternalAdsActive: Bool
    
    private(set) var alertType: UpgradeAccountPlanAlertType?
    @Published var isAlertPresented = false {
        didSet {
            if !isAlertPresented { setAlertType(nil) }
        }
    }
    
    @Published var snackBar: SnackBar?
    @Published var isDismiss = false
    @Published var isLoading = false
    @Published private(set) var currentPlan: PlanEntity?
    @Published var buyButtons: [MEGAButton] = []

    private(set) var recommendedPlanType: AccountTypeEntity?

    @Published var selectedCycleTab: SubscriptionCycleEntity = .yearly {
        didSet { toggleBuyButton() }
    }
    @Published private(set) var selectedPlanType: AccountTypeEntity? {
        didSet { toggleBuyButton() }
    }

    private(set) var registerDelegateTask: Task<Void, Never>?
    private(set) var setUpPlanTask: Task<Void, Never>?
    private(set) var setExternalPurchaseTask: Task<Void, Never>?
    private(set) var buyPlanTask: Task<Void, Never>?
    private(set) var cancelActivePlanAndBuyNewPlanTask: Task<Void, Never>?
    private(set) var observeAccountUpdatesTask: Task<Void, Never>?
    private(set) var updateBuyButtonsTask: Task<Void, Never>?

    @PreferenceWrapper(key: PreferenceKeyEntity.lastCloseAdsButtonTappedDate, defaultValue: nil)
    private var lastCloseAdsDate: Date?
    
    init(
        accountDetails: AccountDetailsEntity,
        accountUseCase: some AccountUseCaseProtocol,
        purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
        subscriptionsUseCase: some SubscriptionsUseCaseProtocol,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase,
        localFeatureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        externalPurchaseUseCase: some ExternalPurchaseUseCaseProtocol = DIContainer.externalPurchaseUseCase,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        viewType: UpgradeAccountPlanViewType,
        router: some UpgradeAccountPlanRouting,
        appVersion: String,
        canOpenURL: @Sendable @escaping (URL) async -> Bool = { UIApplication.shared.canOpenURL($0) },
        openURL: @Sendable @escaping (URL) async -> Void = { UIApplication.shared.open($0) }
    ) {
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.subscriptionsUseCase = subscriptionsUseCase
        self.accountDetails = accountDetails
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        self.localFeatureFlagProvider = localFeatureFlagProvider
        self.externalPurchaseUseCase = externalPurchaseUseCase
        self.tracker = tracker
        self.viewType = viewType
        self.router = router
        self.appVersion = appVersion
        self.canOpenURL = canOpenURL
        self.openURL = openURL
        isExternalAdsActive = remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .externalAds)
        $lastCloseAdsDate.useCase = preferenceUseCase
        registerDelegates()
        setupPlans()
    }
    
    deinit {
        Task { [purchaseUseCase] in
            await purchaseUseCase.deRegisterRestoreDelegate()
            await purchaseUseCase.deRegisterPurchaseDelegate()
        }
        registerDelegateTask?.cancel()
        setUpPlanTask?.cancel()
        buyPlanTask?.cancel()
        cancelActivePlanAndBuyNewPlanTask?.cancel()
        observeAccountUpdatesTask?.cancel()
        registerDelegateTask = nil
        setUpPlanTask = nil
        buyPlanTask = nil
        cancelActivePlanAndBuyNewPlanTask = nil
        observeAccountUpdatesTask = nil
    }
    
    // MARK: - Setup
    private func registerDelegates() {
        guard registerDelegateTask == nil else { return }
        registerDelegateTask = Task {
            await purchaseUseCase.registerRestoreDelegate()
            await purchaseUseCase.registerPurchaseDelegate()
            setupSubscriptions()
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
                    onPurchasePlanSuccessful()
                case .failure(let error):
                    tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseFailedEvent())
                    guard error.toPurchaseErrorStatus() != .paymentCancelled else { return }
                    setAlertType(.purchase(.failed))
                }
            }
            .store(in: &subscriptions)
    }

    private func onPurchasePlanSuccessful(purchasedExternally: Bool = false) {
        tracker.trackAnalyticsEvent(with: UpgradeAccountPurchaseSucceededEvent())
        postAccountDidPurchasedPlanNotification()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            purchaseUseCase.startMonitoringSubmitReceiptAfterPurchase()
            postDismissOnboardingProPlanDialog()
            isDismiss = true
            observeAccountUpdatesTask?.cancel()
        }
    }

    private func setupPlans() {
        setUpPlanTask = Task {
            planList = await purchaseUseCase.accountPlanProducts()
            
            if viewType == .upgrade {
                setRecommendedPlan(basedOnPlan: accountDetails.proLevel)
            } else {
                let lowestPlan = planList.sorted(by: { $0.price < $1.price }).first ?? PlanEntity()
                setRecommendedPlan(basedOnPlan: lowestPlan.type)
            }
            
            setDefaultPlanCycleTab()
            setCurrentPlan(type: accountDetails.proLevel)
        }
    }

    private func toggleBuyButton() {
        guard let currentSelectedPlan else {
            hideBuyButtons()
            return
        }

        if isSelectionEnabled(forPlan: currentSelectedPlan) {
            reloadBuyButtons(for: currentSelectedPlan)
        } else {
            hideBuyButtons()
        }
    }

    private func hideBuyButtons() {
        buyButtons = []
    }

    private func reloadBuyButtons(for plan: PlanEntity) {
        updateBuyButtonsTask?.cancel()
        updateBuyButtonsTask = Task {
            buyButtons = await makeBuyButtons(selectedPlan: plan)
        }
    }

    private func makeBuyButtons(selectedPlan: PlanEntity) async -> [MEGAButton] {
        guard await externalPurchaseUseCase.shouldProvideExternalPurchase() else {
            return [mainBuyButton]
        }

        return [buyExternallyButton, continueInAppButton(plan: selectedPlan)]
    }

    private var mainBuyButton: MEGAButton {
        MEGAButton(Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(
            selectedPlanName
        )) { [weak self] in
            self?.didTap(.buyPlan)
        }
    }

    private var buyExternallyButton: MEGAButton {
        MEGAButton(
            Strings.Localizable.UpgradeAccountPlan.Button.BuyAccountPlan.title(selectedPlanName),
            icon: MEGAAssets.Image.externalLink,
            iconAlignment: .trailing
        ) { [weak self] in
            self?.didTap(.buyExternally)
        }
    }

    private func continueInAppButton(plan: PlanEntity) -> MEGAButton {
        MEGAButton(
            Strings.Localizable.UpgradeAccountPlan.Button.BuyInApp.title(plan.appStoreFormattedPrice),
            footer: Strings.Localizable.UpgradeAccountPlan.Button.BuyInApp.footer,
            type: .secondary
        ) { [weak self] in
            self?.didTap(.buyInApp)
        }
    }

    private func setDefaultPlanCycleTab() {
        selectedCycleTab = accountDetails.subscriptionCycle == .monthly ? .monthly : .yearly
    }
    
    private func setCurrentPlan(type: AccountTypeEntity) {
        guard type != .free else {
            currentPlan = PlanEntity(type: .free, name: AccountTypeEntity.free.toAccountTypeDisplayName())
            return
        }
        
        guard !type.isLowerTierPlan else {
            currentPlan = PlanEntity(type: type, name: type.toAccountTypeDisplayName())
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
    
    private func currentAccountTypeDisplayName() -> String {
        accountDetails.proLevel.toAccountTypeDisplayName()
    }

    // MARK: - Public
    var currentPlanName: String {
        // The user might have a plan that is not available for purchase on the Apple Store.
        // In such cases, the current plan name could be nil.
        // To handle this, we fall back to the user's pro level to determine the plan's name.
        currentPlan?.name ?? currentAccountTypeDisplayName()
    }
    
    var selectedPlanName: String {
        selectedPlanType?.toAccountTypeDisplayName() ?? ""
    }
    
    var filteredPlanList: [PlanEntity] {
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
                                   textColor: MEGAAssets.UIColor.upgradeAccountPrimaryText.swiftUI,
                                   linkColor: TokenColors.Support.success.swiftUI)
    }
    
    var freePlanViewModel: SubscriptionPurchaseFreePlanViewModel {
        .init(maxStorageSize: accountDetails.storageMax)
    }
    
    func createAccountPlanViewModel(_ plan: PlanEntity) -> AccountPlanViewModel {
        AccountPlanViewModel(
            plan: plan,
            planTag: planTag(plan),
            isSelected: isPlanSelected(plan),
            isSelectionEnabled: isSelectionEnabled(forPlan: plan),
            didTapPlan: {
                self.setSelectedPlan(plan)
            })
    }
    
    func setSelectedPlan(_ plan: PlanEntity) {
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
        snackBar = .init(message: type.title)
    }
    
    func didTap(_ target: UpgradeAccountPlanTarget) {
        switch target {
        case .termsAndPolicies:
            router.showTermsAndPolicies()
        case .restorePlan:
            restorePurchase()
        case .buyPlan, .buyExternally:
            buySelectedPlan()
        case .buyInApp:
            buyInApp()
        }
    }
    
    func cancelUpgradeButtonTapped() {
        tracker.trackAnalyticsEvent(with: CancelUpgradeMyAccountEvent())
        isDismiss = true
    }
    
    func onLoad() {
        tracker.trackAnalyticsEvent(with: UpgradeAccountPlanScreenEvent())
    }

    func getStartedButtonTapped() {
        tracker.trackAnalyticsEvent(with: GetStartedForFreeUpgradePlanButtonPressedEvent())
        isDismiss = true
    }

    func mayBeLaterButtonTapped() {
        tracker.trackAnalyticsEvent(with: MaybeLaterUpgradeAccountButtonPressedEvent())
        isDismiss = true
    }

    func onReturnActive() async {
        await checkForAccountUpdates()
    }

    // MARK: - Private
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
    
    private func planTag(_ plan: PlanEntity) -> AccountPlanTagEntity {
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
    
    private func isPlanSelected(_ plan: PlanEntity) -> Bool {
        guard let selectedPlanType else { return false }
        return selectedPlanType == plan.type && isSelectionEnabled(forPlan: plan)
    }
    
    private func isSelectionEnabled(forPlan plan: PlanEntity) -> Bool {
        guard let currentPlan, accountDetails.subscriptionCycle != .none else {
            return true
        }
        return currentPlan != plan
    }
    
    private func startLoading() {
        isLoading = true
    }
    
    // MARK: Restore
    private func restorePurchase() {
        purchaseUseCase.restorePurchase()
    }
    
    // MARK: Buy plan
    var currentSelectedPlan: PlanEntity? {
        guard let selectedPlanType,
              let selectedPlan = filteredPlanList.first(where: { $0.type == selectedPlanType }) else {
            return nil
        }
        return selectedPlan
    }
    
    private func trackEventBuyPlan(_ currentSelectedPlan: PlanEntity) {
        // Track buy event for Ads flow
        if isExternalAdsActive {
            trackEventBuyPlanForAds()
        }
        
        // Track buy event for specific pro plan
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
        buySelectedPlan(purchaseLogic: { [weak self] currentSelectedPlan in
            guard let self else { return }

            if let externalLink = await externalLink(for: currentSelectedPlan) {
                observeAccountUpdates()
                await openURL(externalLink)
                isLoading = false
            } else {
                await purchaseUseCase.purchasePlan(currentSelectedPlan)
            }
        })
    }

    private func buyInApp() {
        buySelectedPlan(purchaseLogic: { [weak self] currentSelectedPlan in
            guard let self else { return }

            await purchaseUseCase.purchasePlan(currentSelectedPlan)
        })
    }

    private func buySelectedPlan(purchaseLogic: @escaping (PlanEntity) async -> Void) {
        guard let currentSelectedPlan else { return }
        
        buyPlanTask = Task { [weak self] in
            guard let self else { return }
            MEGALogDebug("[Upgrade Account] Starting plan purchase.")
            
            do {
                try validateActiveSubscriptions()
                startLoading()

                await purchaseLogic(currentSelectedPlan)

                trackEventBuyPlan(currentSelectedPlan)
            } catch {
                guard let error = error as? ActiveSubscriptionError else {
                    fatalError("[Upgrade Account] Error \(error) is not supported.")
                }
                
                handleActiveSubscription(type: error)
            }
        }
    }

    private func observeAccountUpdates() {
        observeAccountUpdatesTask?.cancel()
        observeAccountUpdatesTask = Task { [weak self, accountUseCase] in
            for await _ in accountUseCase.onAccountUpdates {
                guard let self, !Task.isCancelled else { return }
                guard await checkForAccountUpdates() == true else { continue }

                return
            }
        }
    }

    @discardableResult
    private func checkForAccountUpdates() async -> Bool {
        guard
            let currentSelectedPlan,
            let accountDetailsEntity = try? await accountUseCase.refreshAccountAndMonitorUpdate(),
            accountDetailsEntity.proLevel == currentSelectedPlan.type else {
            return false
        }

        onPurchasePlanSuccessful(purchasedExternally: true)
        return true
    }

    private func externalLink(for plan: PlanEntity) async -> URL? {
        guard
            await externalPurchaseUseCase.shouldProvideExternalPurchase(),
            let externalPurchaseLink = try? await externalPurchaseUseCase.externalPurchaseLink(
                path: plan.externalPurchasePath,
                sourceApp: "iOS app Ver \(appVersion)",
                months: {
                    switch selectedCycleTab {
                    case .monthly: 1
                    case .yearly: 12
                    default: nil
                    }
                }()
            ),
            await canOpenURL(externalPurchaseLink)
        else { return nil }

        return externalPurchaseLink
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
            try await subscriptionsUseCase.cancelSubscriptions()
            await refreshAccountDetails()
        } catch {
            MEGALogError("[Upgrade Account] Unable to cancel active subscription")
        }
    }
    
    // MARK: - Ads
    private func trackEventBuyPlanForAds() {
        if router.isFromAds {
            // User buys a plan coming from the Ad-free flow
            tracker.trackAnalyticsEvent(with: AdFreeDialogUpgradeAccountPlanPageBuyButtonPressedEvent())
        } else {
            // User buys a plan without going through the Ad-free flow but matches these requirements:
            // - The user is using less that 50% of their storage quota
            // - The timestamp on close ads button tap is within the last 2 days
            guard isAdsClosedWithinLastTwoDays() &&
                    hasUsedLessThanHalfQuota(used: accountDetails.storageUsed, quota: accountDetails.storageMax) else {
                return
            }
            
            tracker.trackAnalyticsEvent(with: AdsUpgradeAccountPlanPageBuyButtonPressedEvent())
        }
    }
    
    private func isAdsClosedWithinLastTwoDays() -> Bool {
        guard let lastCloseAdsDate,
              let daysOfDistance = Date().dayDistance(toPastDate: lastCloseAdsDate, on: Calendar.current) else {
            return false
        }
        return daysOfDistance <= 2
    }
    
    private func hasUsedLessThanHalfQuota(used: Int64, quota: Int64) -> Bool {
        used < (quota / 2)
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
