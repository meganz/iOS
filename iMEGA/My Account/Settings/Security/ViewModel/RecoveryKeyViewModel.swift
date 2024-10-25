import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation

enum RecoveryKeyAction: ActionType {
    case onViewDidLoad
    case didTapCopyButton
    case didTapCopyOkAlertButton
    case didTapSaveButton
    case didTapSaveOkAlertButton
    case didTapWhyDoINeedARecoveryKey
}

final class RecoveryKeyViewModel: NSObject, ViewModelType {
    enum Command: CommandType {}
    var invokeCommand: ((Command) -> Void)?
    
    private let accountUseCase: any AccountUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let router: any RecoveryKeyViewRouting
    
    private(set) var saveMasterKeyTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var copyMasterKeyTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    
    init(
        accountUseCase: some AccountUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        router: some RecoveryKeyViewRouting
    ) {
        self.accountUseCase = accountUseCase
        self.tracker = tracker
        self.router = router
    }
    
    deinit {
        saveMasterKeyTask?.cancel()
        copyMasterKeyTask?.cancel()
    }
    
    func dispatch(_ action: RecoveryKeyAction) {
        switch action {
        case .onViewDidLoad:
            tracker.trackAnalyticsEvent(with: RecoveryKeyScreenEvent())
        case .didTapCopyButton:
            tracker.trackAnalyticsEvent(with: RecoveryKeyCopyButtonPressedEvent())
            copyMasterKey()
        case .didTapCopyOkAlertButton:
            tracker.trackAnalyticsEvent(with: RecoveryKeyCopyOkButtonPressedEvent())
        case .didTapSaveButton:
            tracker.trackAnalyticsEvent(with: RecoveryKeySaveButtonPressedEvent())
            saveMasterKey()
        case .didTapSaveOkAlertButton:
            tracker.trackAnalyticsEvent(with: RecoveryKeySaveOkButtonPressedEvent())
        case .didTapWhyDoINeedARecoveryKey:
            tracker.trackAnalyticsEvent(with: RecoveryKeyWhyDoINeedARecoveryKeyButtonPressedEvent())
            router.showSecurityLink()
        }
    }
    
    private func copyMasterKey() {
        guard MEGAReachabilityManager.isReachableHUDIfNot(),
              accountUseCase.isLoggedIn() else {
            return
        }
        
        copyMasterKeyTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await Helper.showMasterKeyCopiedAlert()
            dispatch(.didTapCopyOkAlertButton)
        }
    }
    
    private func saveMasterKey() {
        guard MEGAReachabilityManager.isReachableHUDIfNot(),
              accountUseCase.isLoggedIn(),
              let viewController = router.recoveryKeyViewController else {
            return
        }
        
        saveMasterKeyTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await Helper.showExportMasterKey(inView: viewController)
            dispatch(.didTapSaveOkAlertButton)
        }
    }
}
