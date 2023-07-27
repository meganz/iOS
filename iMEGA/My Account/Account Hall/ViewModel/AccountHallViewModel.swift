import Combine
import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

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
    
    var invokeCommand: ((Command) -> Void)?
    var incomingContactRequestsCount = 0
    var relevantUnseenUserAlertsCount: UInt = 0
    
    private(set) var planList: [AccountPlanEntity] = []
    private(set) var accountDetails: AccountDetailsEntity?
    private var featureFlagProvider: any FeatureFlagProviderProtocol
    
    private let accountHallUsecase: any AccountHallUseCaseProtocol
    private let purchaseUseCase: any AccountPlanPurchaseUseCaseProtocol
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Account Plan view
    @Published private(set) var currentPlanName: String = ""
    @Published private(set) var isUpdatingAccountDetails: Bool = true
    
    // MARK: - Init
    
    init(accountHallUsecase: some AccountHallUseCaseProtocol,
         purchaseUseCase: some AccountPlanPurchaseUseCaseProtocol,
         featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.accountHallUsecase = accountHallUsecase
        self.purchaseUseCase = purchaseUseCase
        self.featureFlagProvider = featureFlagProvider
        setAccountDetails(accountHallUsecase.currentAccountDetails)
    }
    
    // MARK: Feature flags
    func isNewUpgradeAccountPlanEnabled() -> Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .newUpgradeAccountPlanUI)
    }
    
    func isDeviceCenterEnabled() -> Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .deviceCenter)
    }
    
    // MARK: - Dispatch actions
    
    func dispatch(_ action: AccountHallAction) {
        switch action {
        case .reloadUI:
            invokeCommand?(.reloadUIContent)
        case .load(let target):
            loadContent(target)
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
        accountDetails = details
        currentPlanName = details?.proLevel.toAccountTypeDisplayName() ?? ""
    }
    
    private func loadContent(_ target: AccountHallLoadTarget) {
        switch target {
        case .planList:
            fetchPlanList()
        case .accountDetails:
            let showActivityIndicator = accountDetails == nil
            fetchAccountDetails(showActivityIndicator: showActivityIndicator)
        case .contentCounts:
            fetchCounts()
        }
    }
    
    private func fetchPlanList() {
        Task {
            planList = await purchaseUseCase.accountPlanProducts()
            await configPlanDisplay()
        }
    }
    
    private func fetchAccountDetails(showActivityIndicator: Bool) {
        isUpdatingAccountDetails = showActivityIndicator
        
        Task { @MainActor in
            do {
                let accountDetails = try await accountHallUsecase.refreshCurrentAccountDetails()
                setAccountDetails(accountDetails)
                isUpdatingAccountDetails = false
                configPlanDisplay()
            } catch {
                isUpdatingAccountDetails = false
                MEGALogError("[Account Hall] Error loading account details. Error: \(error)")
            }
        }
    }
    
    private func fetchCounts() {
        Task {
            incomingContactRequestsCount = await accountHallUsecase.incomingContactsRequestsCount()
            relevantUnseenUserAlertsCount = await accountHallUsecase.relevantUnseenUserAlertsCount()
            
            await reloadNotificationCounts()
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
                relevantUnseenUserAlertsCount = newCount
                invokeCommand?(.reloadCounts)
            }
            .store(in: &subscriptions)
        
        NotificationCenter
            .default
            .publisher(for: .refreshAccountDetails)
            .sink { [weak self] _ in
                guard let self else { return }
                fetchAccountDetails(showActivityIndicator: true)
            }
            .store(in: &subscriptions)
    }
    
    private func handleRequestResult(_ result: Result<AccountRequestEntity, Error>) {
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
