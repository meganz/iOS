import Foundation
import MEGADomain

public final class CurrentPlanDetailViewModel {
    let currentPlanName: String
    let currentPlanStorageUsed: String
    let features: [FeatureDetails]
    let router: CurrentPlanDetailRouting
    
    init(
        currentPlanName: String,
        currentPlanStorageUsed: String,
        features: [FeatureDetails],
        router: CurrentPlanDetailRouting
    ) {
        self.currentPlanName = currentPlanName
        self.currentPlanStorageUsed = currentPlanStorageUsed
        self.features = features
        self.router = router
    }
    
    func dismiss() {
        router.dismiss()
    }
}
