import Combine
import DeviceCenter
import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift

enum MyAccountSection: Int, CaseIterable {
    case mega = 0, other
}

enum MyAccountMegaSection: Int, CaseIterable {
    case plan = 0, storage, myAccount, contacts, notifications, achievements, transfers, deviceCenter, offline, rubbishBin
}

enum MyAccountOtherSection: Int, CaseIterable {
    case settings
}

enum MyAccountHallLoadTarget {
    case planList, accountDetails, contentCounts, promos
}

enum MyAccountHallAction: ActionType {
    case viewDidLoad
    case reloadUI
    case load(_ target: MyAccountHallLoadTarget)
    case didTapUpgradeButton
    case addSubscriptions
    case removeSubscriptions
    case didTapDeviceCenterButton
    case navigateToProfile
    case navigateToUsage
    case navigateToSettings
    case didTapMyAccountButton
    case didTapAccountHeader
}

final class MyAccountHallViewModel: ViewModelType, ObservableObject {
    
    enum Command: CommandType, Equatable {
        case reloadCounts
        case reloadUIContent
        case configPlanDisplay
        case setUserAvatar
        case setName
    }

    @Atomic var relevantUnseenUserAlertsCount: UInt = 0
    @Atomic var accountDetails: AccountDetailsEntity?
    @Atomic var arePromosAvailable: Bool = false

    var invokeCommand: ((Command) -> Void)?
    var incomingContactRequestsCount = 0
    var unreadNotificationsCount = 0

    private(set) var planList: [AccountPlanEntity] = []
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    private let myAccountHallUseCase: any MyAccountHallUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    private let notificationsUseCase: any NotificationsUseCaseProtocol
    private let tracker: any AnalyticsTracking
    let shareUseCase: any ShareUseCaseProtocol
    let deviceCenterBridge: DeviceCenterBridge
    let router: any MyAccountHallRouting
    
    private var subscriptions = Set<AnyCancellable>()
    var loadContentTask: Task<Void, Never>?
    
    // MARK: Account Plan view
    @Published private(set) var currentPlanName: String = ""
    @Published private(set) var isUpdatingAccountDetails: Bool = true
    
    // MARK: - Init
    
    init(myAccountHallUseCase: some MyAccountHallUseCaseProtocol,
         accountUseCase: some AccountUseCaseProtocol,
         purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
         shareUseCase: some ShareUseCaseProtocol,
         notificationsUseCase: some NotificationsUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
         deviceCenterBridge: DeviceCenterBridge,
         tracker: some AnalyticsTracking,
         router: some MyAccountHallRouting) {
        self.myAccountHallUseCase = myAccountHallUseCase
        self.accountUseCase = accountUseCase
        self.purchaseUseCase = purchaseUseCase
        self.shareUseCase = shareUseCase
        self.notificationsUseCase = notificationsUseCase
        self.featureFlagProvider = featureFlagProvider
        self.deviceCenterBridge = deviceCenterBridge
        self.tracker = tracker
        self.router = router
        
        setAccountDetails(myAccountHallUseCase.currentAccountDetails)
        makeDeviceCenterBridge()
    }
    
    deinit {
        loadContentTask?.cancel()
    }
    
    // MARK: Feature flags
    func isNotificationCenterEnabled() -> Bool { true }
    
    var isCancelSubscriptionFeatureFlagEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .cancelSubscription)
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: MyAccountHallAction) {
        switch action {
        case .viewDidLoad:
            trackAccountScreenEvent()
        case .reloadUI:
            invokeCommand?(.reloadUIContent)
        case .load(let target):
            loadContentTask = Task { [weak self] in
                guard let self else { return }
                await loadContent(target)
            }
        case .didTapUpgradeButton:
            showUpgradeAccountPlanView()
        case .addSubscriptions:
            registerRequestDelegates()
        case .removeSubscriptions:
            deRegisterRequestDelegates()
        case .didTapDeviceCenterButton:
            router.navigateToDeviceCenter(
                deviceCenterBridge: deviceCenterBridge,
                deviceCenterAssets: makeDeviceCenterAssetData()
            )
        case .navigateToProfile: router.navigateToProfile()
        case .navigateToUsage: router.navigateToUsage()
        case .navigateToSettings: router.navigateToSettings()
        case .didTapMyAccountButton:
            trackMyAccountEvent()
        case .didTapAccountHeader:
            trackAccountHeaderEvent()
        }
    }
    
    private func trackAccountScreenEvent() {
        tracker.trackAnalyticsEvent(with: AccountScreenEvent())
    }
    
    private func trackMyAccountEvent() {
        tracker.trackAnalyticsEvent(with: MyAccountProfileNavigationItemEvent())
    }
    
    private func trackAccountHeaderEvent() {
        tracker.trackAnalyticsEvent(with: AccountScreenHeaderTappedEvent())
    }
    
    private func showUpgradeAccountPlanView() {
        guard let accountDetails else { return }
        let upgradePlanRouter = UpgradeAccountPlanRouter(
            presenter: UIApplication.mnz_presentingViewController(),
            accountDetails: accountDetails
        )
        upgradePlanRouter.start()
    }
    
    // MARK: - Public
    var currentUserHandle: HandleEntity? {
        myAccountHallUseCase.currentUserHandle
    }
    
    var userFullName: String? {
        guard let userHandle = currentUserHandle else { return nil }
        return MEGAUser.mnz_fullName(userHandle)
    }
    
    var isMasterBusinessAccount: Bool {
        myAccountHallUseCase.isMasterBusinessAccount
    }
    
    var showPlanRow: Bool {
        !isBusinessAccount && !isProFlexiAccount
    }
    
    var transferUsed: Int64 {
        accountDetails?.transferUsed ?? 0
    }
    
    var transferMax: Int64 {
        accountDetails?.transferMax ?? 0
    }
    
    var storageUsed: Int64 {
        accountDetails?.storageUsed ?? 0
    }
    
    var storageMax: Int64 {
        accountDetails?.storageMax ?? 0
    }
    
    var isBusinessAccount: Bool {
        accountDetails?.proLevel == .business
    }
    
    var isProFlexiAccount: Bool {
        accountDetails?.proLevel == .proFlexi
    }
    
    var rubbishBinFormattedStorageUsed: String {
        let rubbishBinStorageUsed = accountUseCase.rubbishBinStorageUsed()
        return String
            .memoryStyleString(fromByteCount: rubbishBinStorageUsed)
            .formattedByteCountString()
    }
    
    func calculateCellHeight(at indexPath: IndexPath) -> CGFloat {
        guard indexPath.section != MyAccountSection.other.rawValue else {
            return UITableView.automaticDimension
        }
        
        var shouldShowCell = true
        switch MyAccountMegaSection(rawValue: indexPath.row) {
        case .plan:
            shouldShowCell = showPlanRow
        case .myAccount:
            shouldShowCell = isCancelSubscriptionFeatureFlagEnabled
        case .achievements:
            shouldShowCell = myAccountHallUseCase.isAchievementsEnabled
        default: break
        }
        
        return shouldShowCell ? UITableView.automaticDimension : 0.0
    }
    
    // MARK: - Private
    private func setAccountDetails(_ details: AccountDetailsEntity?) {
        $accountDetails.mutate { currentValue in
            currentValue = details
        }
        Task { @MainActor in
            currentPlanName = details?.proLevel.toAccountTypeDisplayName() ?? ""
        }
    }
    
    private func loadContent(_ target: MyAccountHallLoadTarget) async {
        switch target {
        case .planList:
            await fetchPlanList()
        case .accountDetails:
            let showActivityIndicator = accountDetails == nil
            await fetchAccountDetails(showActivityIndicator: showActivityIndicator)
        case .contentCounts:
            await fetchCounts()
        case .promos:
            await fetchAvailablePromos()
        }
    }
    
    private func fetchPlanList() async {
        planList = await purchaseUseCase.accountPlanProducts()
        await configPlanDisplay()
    }
    
    private func fetchAccountDetails(showActivityIndicator: Bool) async {
        await setIsUpdatingAccountDetails(showActivityIndicator)
        
        do {
            let accountDetails = try await myAccountHallUseCase.refreshCurrentAccountDetails()
            setAccountDetails(accountDetails)
            await setIsUpdatingAccountDetails(false)
            await configPlanDisplay()
        } catch {
            await setIsUpdatingAccountDetails(false)
            MEGALogError("[Account Hall] Error loading account details. Error: \(error)")
        }
    }
    
    private func fetchCounts() async {
        incomingContactRequestsCount = await myAccountHallUseCase.incomingContactsRequestsCount()
        let relevantUnseenUserAlertsCount = await myAccountHallUseCase.relevantUnseenUserAlertsCount()
        $relevantUnseenUserAlertsCount.mutate { currentValue in
            currentValue = relevantUnseenUserAlertsCount
        }
        
        if isNotificationCenterEnabled() {
            unreadNotificationsCount = await notificationsUseCase.unreadNotificationIDs().count
        }

        await reloadNotificationCounts()
    }
    
    private func fetchAvailablePromos() async {
        $arePromosAvailable.mutate { [weak self] currentValue in
            guard let self else { return }
            let hasEnabledNotifications = notificationsUseCase.fetchEnabledNotifications().isNotEmpty
            currentValue = isNotificationCenterEnabled() && hasEnabledNotifications
        }
    }
    
    // MARK: UI
    @MainActor
    private func reloadNotificationCounts() {
        invokeCommand?(.reloadCounts)
    }
    
    @MainActor
    private func configPlanDisplay() {
        invokeCommand?(.configPlanDisplay)
    }
    
    @MainActor
    private func setIsUpdatingAccountDetails(_ isUpdating: Bool) {
        isUpdatingAccountDetails = isUpdating
    }
    
    // MARK: Subscriptions
    private func registerRequestDelegates() {
        Task {
            await myAccountHallUseCase.registerMEGARequestDelegate()
            await myAccountHallUseCase.registerMEGAGlobalDelegate()
            setupSubscriptions()
        }
    }
    
    private func deRegisterRequestDelegates() {
        Task.detached { [weak self] in
            await self?.myAccountHallUseCase.deRegisterMEGARequestDelegate()
            await self?.myAccountHallUseCase.deRegisterMEGAGlobalDelegate()
        }
    }
    
    private func setupSubscriptions() {
        myAccountHallUseCase.requestResultPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                handleRequestResult(result)
            }
            .store(in: &subscriptions)
        
        myAccountHallUseCase.contactRequestPublisher()
            .map { $0.count }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCount in
                guard let self else { return }
                incomingContactRequestsCount = newCount
                invokeCommand?(.reloadCounts)
            }
            .store(in: &subscriptions)
        
        myAccountHallUseCase.userAlertUpdatePublisher()
            .map { UInt($0.count) }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCount in
                guard let self else { return }
                $relevantUnseenUserAlertsCount.mutate { currentValue in
                    currentValue = newCount
                }
                invokeCommand?(.reloadCounts)
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .refreshAccountDetails)
            .map({ $0.object as? AccountDetailsEntity })
            .sink { [weak self] account in
                guard let self else { return }
                Task { [weak self] in
                    guard let self else { return }
                    
                    guard let account else {
                        await fetchAccountDetails(showActivityIndicator: true)
                        return
                    }
                    
                    setAccountDetails(account)
                    await configPlanDisplay()
                }
            }
            .store(in: &subscriptions)
    }
    
    private func handleRequestResult(_ result: Result<AccountRequestEntity, any Error>) {
        if case .success(let request) = result {
            switch request.type {
            case .accountDetails:
                invokeCommand?(.reloadUIContent)
            case .getAttrUser:
                if request.file != nil {
                    invokeCommand?(.setUserAvatar)
                }

                if (request.userAttribute == .firstName || request.userAttribute == .lastName) &&
                    request.email == nil {
                    invokeCommand?(.setName)
                }
            default:
                MEGALogDebug("[Account Hall] Received \(request.type) request type but will not handle here")
                return
            }
        }
    }
}
