import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

public final class CancelAccountPlanViewModel: ObservableObject {
    let currentPlanName: String
    let currentPlanStorageUsed: String
    let freeAccountStorageLimit: Int
    let featureListHelper: FeatureListHelperProtocol
    let router: CancelAccountPlanRouting
    private let achievementUseCase: any AchievementUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let currentSubscription: AccountSubscriptionEntity
    @Published var showCancellationSurvey: Bool = false
    @Published var showCancellationSteps: Bool = false
    
    private let tracker: any AnalyticsTracking
    private let logger: ((String) -> Void)?
    
    @Published private(set) var features: [FeatureDetails] = []
    
    init(
        currentSubscription: AccountSubscriptionEntity,
        featureListHelper: FeatureListHelperProtocol,
        freeAccountStorageLimit: Int,
        achievementUseCase: some AchievementUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        tracker: some AnalyticsTracking,
        logger: ((String) -> Void)? = nil,
        router: CancelAccountPlanRouting
    ) {
        self.currentSubscription = currentSubscription
        self.freeAccountStorageLimit = freeAccountStorageLimit
        self.currentPlanName = accountUseCase.currentAccountDetails?.proLevel.toAccountTypeDisplayName() ?? ""
        self.currentPlanStorageUsed = String.memoryStyleString(fromByteCount: accountUseCase.currentAccountDetails?.storageUsed ?? 0)
        self.achievementUseCase = achievementUseCase
        self.accountUseCase = accountUseCase
        self.featureListHelper = featureListHelper
        self.tracker = tracker
        self.logger = logger
        self.router = router
    }
    
    var cancellationStepsSubscriptionType: SubscriptionType {
        currentSubscription.paymentMethodId == .googleWallet ? .google : .webClient
    }
    
    @MainActor
    func setupFeatureList() async {
        guard freeAccountStorageLimit > 0 else {
            dismiss()
            return
        }
        
        features = featureListHelper.createCurrentFeatures(
            baseStorage: freeAccountStorageLimit
        )
    }
    
    @MainActor
    func dismiss() {
        tracker.trackAnalyticsEvent(with: CancelSubscriptionKeepPlanButtonPressedEvent())
        router.dismissCancellationFlow()
    }
    
    @MainActor
    func didTapContinueCancellation() {
        tracker.trackAnalyticsEvent(with: CancelSubscriptionContinueCancellationButtonPressedEvent())
        
        switch currentSubscription.paymentMethodId {
        case .googleWallet:
            // Show cancellation step for google subscriptions.
            showCancellationSteps = true
        default:
            // Show cancellation survey. For WebClient or Apple subscriptions.
            showCancellationSurvey = true
        }
    }
    
    func makeCancellationSurveyViewModel() -> CancellationSurveyViewModel {
        CancellationSurveyViewModel(
            subscription: currentSubscription,
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            cancelAccountPlanRouter: router,
            logger: logger
        )
    }
}
