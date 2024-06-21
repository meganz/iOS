import Foundation
import MEGAAnalyticsiOS
import MEGADomain
import MEGAPresentation

public final class CancelAccountPlanViewModel: ObservableObject {
    let currentPlanName: String
    let currentPlanStorageUsed: String
    let featureListHelper: FeatureListHelperProtocol
    let router: CancelAccountPlanRouting
    
    private let tracker: any AnalyticsTracking
    
    @Published private(set) var features: [FeatureDetails] = []

    init(
        currentPlanName: String,
        currentPlanStorageUsed: String,
        featureListHelper: FeatureListHelperProtocol,
        tracker: some AnalyticsTracking,
        router: CancelAccountPlanRouting
    ) {
        self.currentPlanName = currentPlanName
        self.currentPlanStorageUsed = currentPlanStorageUsed
        self.featureListHelper = featureListHelper
        self.tracker = tracker
        self.router = router
    }
    
    @MainActor
    func setupFeatureList() {
        features = featureListHelper.createCurrentFeatures()
    }
    
    func dismiss() {
        tracker.trackAnalyticsEvent(with: CancelSubscriptionKeepPlanButtonPressedEvent())
        router.dismiss()
    }
    
    func showCancelSubscriptionSteps() {
        tracker.trackAnalyticsEvent(with: CancelSubscriptionContinueCancellationButtonPressedEvent())
        router.showCancellationSteps()
    }
}
