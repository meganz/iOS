import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo

@MainActor
public final class CancelAccountPlanViewModel: ObservableObject {
    let currentPlanName: String
    let currentPlanStorageUsed: String
    let freeAccountStorageLimit: Int
    let featureListHelper: any FeatureListHelperProtocol
    let router: any CancelAccountPlanRouting
    private let achievementUseCase: any AchievementUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let currentSubscription: AccountSubscriptionEntity
    @Published var showCancellationSurvey: Bool = false
    @Published var showCancellationSteps: Bool = false
    
    private let tracker: any AnalyticsTracking
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    @Published private(set) var features: [FeatureDetails] = []
    
    init(
        currentSubscription: AccountSubscriptionEntity,
        featureListHelper: some FeatureListHelperProtocol,
        freeAccountStorageLimit: Int,
        achievementUseCase: some AchievementUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        tracker: some AnalyticsTracking,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        router: some CancelAccountPlanRouting
    ) {
        self.currentSubscription = currentSubscription
        self.freeAccountStorageLimit = freeAccountStorageLimit
        self.currentPlanName = accountUseCase.currentAccountDetails?.proLevel.toAccountTypeDisplayName() ?? ""
        self.currentPlanStorageUsed = String.memoryStyleString(fromByteCount: accountUseCase.currentAccountDetails?.storageUsed ?? 0)
        self.achievementUseCase = achievementUseCase
        self.accountUseCase = accountUseCase
        self.featureListHelper = featureListHelper
        self.tracker = tracker
        self.featureFlagProvider = featureFlagProvider
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
        case .itunes:
            // Show cancellation survey for Apple subscriptions.
            showCancellationSurvey = true
        case .googleWallet:
            // Show cancellation steps for Google subscriptions.
            showCancellationSteps = true
        default:
            // Webclient payment methods
            if featureFlagProvider.isFeatureFlagEnabled(for: .webclientSubscribersCancelSubscription),
                currentSubscription.paymentMethodId == .stripe || currentSubscription.paymentMethodId == .stripe2 {
                // Show cancellation survey for stripe payment methods, if the feature flag is enabled.
                showCancellationSurvey = true
            } else {
                // Show cancellation steps if not.
                showCancellationSteps = true
            }
        }
    }
    
    @MainActor
    func makeCancellationSurveyViewModel() -> CancellationSurveyViewModel {
        CancellationSurveyViewModel(
            subscription: currentSubscription,
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            accountUseCase: accountUseCase,
            cancelAccountPlanRouter: router,
            featureFlagProvider: featureFlagProvider
        )
    }
}
