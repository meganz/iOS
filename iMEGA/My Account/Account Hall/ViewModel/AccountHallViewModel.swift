import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MEGASwift

enum AccountHallLoadTarget {
    case planList, accountDetails, contentCounts
}

enum AccountHallAction: ActionType {
    case reloadUI
    case load(_ target: AccountHallLoadTarget)
    case didTapUpgradeButton
    case addSubscriptions
    case removeSubscriptions
}

final class AccountHallViewModel: ViewModelType, ObservableObject {
    
    enum Command: CommandType, Equatable {
        case reloadCounts
        case reloadUIContent
        case configPlanDisplay
        case setUserAvatar
        case setName
    }

    @Atomic var relevantUnseenUserAlertsCount: UInt = 0
    @Atomic var isNewUpgradeAccountPlanEnabled: Bool = false
    @Atomic var accountDetails: AccountDetailsEntity?

    var invokeCommand: ((Command) -> Void)?
    var incomingContactRequestsCount = 0
    var setupABTestVariantTask: Task<Void, Never>?

    private(set) var planList: [AccountPlanEntity] = []
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    private var abTestProvider: any ABTestProviderProtocol
    private let accountHallUsecase: any AccountHallUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    
    private var subscriptions = Set<AnyCancellable>()
    var loadContentTask: Task<Void, Never>?
    
    // MARK: Account Plan view
    @Published private(set) var currentPlanName: String = ""
    @Published private(set) var isUpdatingAccountDetails: Bool = true
    
    // MARK: - Init
    
    init(accountHallUsecase: some AccountHallUseCaseProtocol,
         purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
         abTestProvider: some ABTestProviderProtocol = DIContainer.abTestProvider) {
        self.accountHallUsecase = accountHallUsecase
        self.purchaseUseCase = purchaseUseCase
        self.featureFlagProvider = featureFlagProvider
        self.abTestProvider = abTestProvider
        
        setupABTestVariant()
        setAccountDetails(accountHallUsecase.currentAccountDetails)
    }
    
    deinit {
        loadContentTask?.cancel()
    }
    
    // MARK: Feature flags
    func isDeviceCenterEnabled() -> Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .deviceCenter)
    }
    
    // MARK: A/B testing
    func setupABTestVariant() {
        setupABTestVariantTask = Task { [weak self] in
            guard let self else { return }
            let isNewUpgradeAccountPlanEnabled = await abTestProvider.abTestVariant(for: .upgradePlanRevamp) == .variantA
            $isNewUpgradeAccountPlanEnabled.mutate { currentValue in
                currentValue = isNewUpgradeAccountPlanEnabled
            }
        }
    }

    // MARK: - Dispatch actions
    
    func dispatch(_ action: AccountHallAction) {
        switch action {
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
        }
    }
    
    private func showUpgradeAccountPlanView() {
        guard let accountDetails else { return }
        let upgradePlanRouter = UpgradeAccountPlanRouter(presenter: UIApplication.mnz_presentingViewController(),
                                                         accountDetails: accountDetails)
        upgradePlanRouter.start()
    }
    
    // MARK: - Public
    var currentUserHandle: HandleEntity? {
        accountHallUsecase.currentUserHandle
    }
    
    var userFullName: String? {
        guard let userHandle = currentUserHandle else { return nil }
        return MEGAUser.mnz_fullName(userHandle)
    }
    
    var isMasterBusinessAccount: Bool {
        accountHallUsecase.isMasterBusinessAccount
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
    
    private func loadContent(_ target: AccountHallLoadTarget) async {
        switch target {
        case .planList:
            await fetchPlanList()
        case .accountDetails:
            let showActivityIndicator = accountDetails == nil
            await fetchAccountDetails(showActivityIndicator: showActivityIndicator)
        case .contentCounts:
            await fetchCounts()
        }
    }
    
    private func fetchPlanList() async {
        planList = await purchaseUseCase.accountPlanProducts()
        await configPlanDisplay()
    }
    
    private func fetchAccountDetails(showActivityIndicator: Bool) async {
        await setIsUpdatingAccountDetails(showActivityIndicator)
        
        do {
            let accountDetails = try await accountHallUsecase.refreshCurrentAccountDetails()
            setAccountDetails(accountDetails)
            await setIsUpdatingAccountDetails(false)
            await configPlanDisplay()
        } catch {
            await setIsUpdatingAccountDetails(false)
            MEGALogError("[Account Hall] Error loading account details. Error: \(error)")
        }
    }
    
    private func fetchCounts() async {
        incomingContactRequestsCount = await accountHallUsecase.incomingContactsRequestsCount()
        let relevantUnseenUserAlertsCount = await accountHallUsecase.relevantUnseenUserAlertsCount()
        $relevantUnseenUserAlertsCount.mutate { currentValue in
            currentValue = relevantUnseenUserAlertsCount
        }
        
        await reloadNotificationCounts()
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
            await accountHallUsecase.registerMEGARequestDelegate()
            await accountHallUsecase.registerMEGAGlobalDelegate()
            setupSubscriptions()
        }
    }
    
    private func deRegisterRequestDelegates() {
        Task.detached { [weak self] in
            await self?.accountHallUsecase.deRegisterMEGARequestDelegate()
            await self?.accountHallUsecase.deRegisterMEGAGlobalDelegate()
        }
    }
    
    private func setupSubscriptions() {
        accountHallUsecase.requestResultPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                handleRequestResult(result)
            }
            .store(in: &subscriptions)
        
        accountHallUsecase.contactRequestPublisher()
            .map { $0.count }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCount in
                guard let self else { return }
                incomingContactRequestsCount = newCount
                invokeCommand?(.reloadCounts)
            }
            .store(in: &subscriptions)
        
        accountHallUsecase.userAlertUpdatePublisher()
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
