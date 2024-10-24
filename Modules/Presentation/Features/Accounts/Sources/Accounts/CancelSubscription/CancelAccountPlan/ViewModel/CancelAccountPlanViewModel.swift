import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

public final class CancelAccountPlanViewModel: ObservableObject {
    let currentPlanName: String
    let currentPlanStorageUsed: String
    let featureListHelper: FeatureListHelperProtocol
    let router: CancelAccountPlanRouting
    private let achievementUseCase: any AchievementUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private let currentSubscription: AccountSubscriptionEntity
    @Published var showCancellationSurvey: Bool = false
    @Published var showCancellationSteps: Bool = false
    
    private let tracker: any AnalyticsTracking
    
    @Published private(set) var features: [FeatureDetails] = []
    
    init(
        currentSubscription: AccountSubscriptionEntity,
        featureListHelper: FeatureListHelperProtocol,
        achievementUseCase: some AchievementUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol,
        tracker: some AnalyticsTracking,
        router: CancelAccountPlanRouting
    ) {
        self.currentSubscription = currentSubscription
        self.currentPlanName = accountUseCase.currentAccountDetails?.proLevel.toAccountTypeDisplayName() ?? ""
        self.currentPlanStorageUsed = String.memoryStyleString(fromByteCount: accountUseCase.currentAccountDetails?.storageUsed ?? 0)
        self.achievementUseCase = achievementUseCase
        self.accountUseCase = accountUseCase
        self.featureListHelper = featureListHelper
        self.tracker = tracker
        self.router = router
    }
    
    var cancellationStepsSubscriptionType: SubscriptionType {
        currentSubscription.paymentMethodId == .googleWallet ? .google : .webClient
    }
    
    @MainActor
    func setupFeatureList() async {
        do {
            let bytesBaseStorage = try await achievementUseCase.baseStorage()
            features = featureListHelper.createCurrentFeatures(
                baseStorage: bytesBaseStorage.bytesToGigabytes()
            )
        } catch {
            dismiss()
        }
    }
    
    func dismiss() {
        tracker.trackAnalyticsEvent(with: CancelSubscriptionKeepPlanButtonPressedEvent())
        router.dismissCancellationFlow()
    }
    
    @MainActor
    func didTapContinueCancellation() {
        tracker.trackAnalyticsEvent(with: CancelSubscriptionContinueCancellationButtonPressedEvent())
        
        if currentSubscription.paymentMethodId == .itunes {
            // Show cancellation survey. This is only for Apple subscriptions.
            showCancellationSurvey = true
        } else {
            // Show cancellation step for either google or webclient subscriptions
            showCancellationSteps = true
        }
    }
    
    func makeCancellationSurveyViewModel() -> CancellationSurveyViewModel {
        CancellationSurveyViewModel(
            subscription: currentSubscription,
            subscriptionsUseCase: SubscriptionsUseCase(repo: SubscriptionsRepository.newRepo),
            cancelAccountPlanRouter: router)
    }
}
